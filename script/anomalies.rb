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
config = YAML::load(File.open(ARGV.first))

path = File.dirname(__FILE__)

list = config['file-project-list']
prefix = config['dir-project-prefix']
suffix = config['dir-project-suffix']

perlexpr = 'print $_ unless Mail::RFC822::Address::valid($_)'
check = "perl -I#{path} -MAddress -ne '#{perlexpr}'"
cmd = "git --git-dir #{prefix}/$X#{suffix} log --pretty='%aE%x0A%cE'"
system "cat #{list} | while read X Y; do #{cmd}; done | sort | uniq | #{check}"

