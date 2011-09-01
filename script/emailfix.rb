#!/usr/bin/env ruby

# Copyright (C) 2011  Rafael S. Suguiura <rafael.suguiura@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'uri'
require 'optparse'
require 'yaml'

opts = ARGV.getopts('', 'no-fix', 'fix-only', 'mailmap')
$config = YAML.load_file('config/servers.yaml')

servers = $config[:servers].keys
servers &= ARGV.map{|x| x.to_sym} unless ARGV.empty?

projects = YAML.load_file $config[:global][:list][:file]

perlexpr = 'print $_ unless Mail::RFC822::Address::valid($_)'
check = "perl -I#{File.dirname(__FILE__)} -MAddress -ne '#{perlexpr}'"
git = ["git --git-dir ", " log --pretty='%aE%x0A%cE'"]

emails = Hash[servers.map do |server| n = projects[server].size
  STDERR.puts "Retrieving, selecting and fixing emails for #{server}..."
  bad_emails = []
  projects[server].each do |path, project| n -= 1
    STDERR.printf " %5d - %s\n", n, path
    IO.popen "#{git.join(project[:dir])} | sort | uniq | #{check}" do |io|
      bad_emails |= io.read.split("\n")
    end
  end

  bad_emails.map do |bad_email| bad_email.strip!
    next if bad_email.include? '(none)'
    email = URI.unescape(bad_email)
    email.gsub! /DOT/, '.'
    email.gsub! /AT/, '@'
    email.downcase!
    email.gsub! /[^-._@a-z0-9]/, ' '
    email.squeeze! ' '
    email.gsub! /[ _.-]+at[-._ ]+/, '@'
    email.gsub! /[ _.-]+dot[-._ ]+/, '.'
    email.gsub! /^[ _.-]+|[-._ ]+$/, ''
    email.sub!(' ', '@') if email.count('@') == 0
    email.gsub! ' ', '.'
    email.squeeze! '.'
    next unless email.match(/^[[:alpha:]]*$/).nil?
    [bad_email, email]
  end
end.flatten]

filename = $config[:global][:emailfix][:file]
emails.update(Hash[YAML.load_file(filename)]) if File.exists? filename
File.open(filename, 'w').puts case
when opts['no-fix'] then emails.keys.sort.join("\n")
when opts['fix-only'] then emails.values.sort.join("\n")
when opts['mailmap'] then emails.sort.map{|x|"<#{x.last}> <#{x.first}>"}.join("\n")
else emails.sort.to_yaml[5..-1]
end

