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

$: << File.join(File.dirname(__FILE__), '.')
require 'config'

selection = ARGV.map{|x| x.to_sym}
keys = $config[:servers].keys
keys &= selection unless selection.empty?

emailfixfile = $config[:global][:emailfix][:file]
system "mkdir -p $(dirname #{emailfixfile}); touch #{emailfixfile}"
emails = YAML.load_file(emailfixfile) || {}

perlexpr = 'print $_ unless Mail::RFC822::Address::valid($_)'
check = "perl -I#{File.dirname(__FILE__)} -MAddress -ne '#{perlexpr}'"

keys.each do |server| $l.info "Fixing emails for #{server}..."
  n = $projects[server].size
  $projects[server].each do |path, project| n -= 1
    $l.info "%5d - %s" % (n, path)
    dir, range = project[:dir], project[:range]
    git = "git --git-dir #{dir} log --pretty='%aE%x0A%cE' #{range}"
    cmd = "#{git} | sort | uniq | #{check}"
    IO.popen(cmd){|io|io.read}.split("\n").each do |bad_email|
      next unless emails[bad_email].nil?
      next if bad_email.include? '(none)'
      bad_email.strip!
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
      emails[bad_email] = email
    end
  end
end

File.open(emailfixfile, 'w').puts emails.to_yaml
$l.info 'Done.'

