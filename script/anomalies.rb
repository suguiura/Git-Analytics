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

opts = ARGV.getopts('', 'no-fix', 'plain', 'mailmap')
config = YAML.load_file(ARGV.first)
projects = YAML.load_file(config[:list][:file])

perlexpr = 'print $_ unless Mail::RFC822::Address::valid($_)'
check = "perl -I#{File.dirname(__FILE__)} -MAddress -ne '#{perlexpr}'"
git = ["git --git-dir ", " log --pretty='%aE%x0A%cE'"]
projects.each_index do |i| project = projects[i]
  STDERR.printf "%5d/%d - %s\n", i + 1, projects.size, project[:path]
  IO.popen "#{git.join(project[:dir])} | sort | uniq | #{check}" do |io|
    if opts['no-fix']
      puts io.read
    else
      io.read.each_line do |line|
        line.strip!
        email = URI.unescape(line)
        email.gsub!(/DOT/, '.')
        email.gsub!(/AT/, '@')
        email.downcase!
        email.gsub!(/[^-._@a-z0-9]/, ' ')
        email.squeeze!(' ')
        email.gsub!(/[ _.-]+at[-._ ]+/, '@')
        email.gsub!(/[ _.-]+dot[-._ ]+/, '.')
        email.gsub!(/^[ _.-]+|[-._ ]+$/, '')
        email.sub!(' ', '@') if email.count('@') == 0
        email.gsub!(' ', '.')
        email.squeeze!('.')
        email = email.split('@').last if email.include? 'no.author.'
        email = email.split('@').first if email.include? '.none'
        (puts "<#{email}> <#{line}>"; next) if opts['mailmap']
        (puts email; next) if opts['plain']
        puts [[line, email]].to_yaml[5..-1]
      end
    end
  end
end

