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

require 'yaml'

config = YAML.load_file(ARGV.first)
projects = YAML.load_file(config[:list][:file])

perlexpr = 'print $_ unless Mail::RFC822::Address::valid($_)'
check = "perl -I#{File.dirname(__FILE__)} -MAddress -ne '#{perlexpr}'"
projects.each_index do |i| project = projects[i]
  STDERR.printf "%5d/%d - %s\n", i + 1, projects.size, project[:path]
  system "git --git-dir #{project[:dir]} log --pretty='%aE%x0A%cE' | #{check}"
end

