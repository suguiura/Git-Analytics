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

require 'optparse'
opts = ARGV.getopts('', 'to:')

dest = opts['to'] || '.'

prefix = config['url-git-prefix']
suffix = config['url-git-suffix']



cmds = "git clone --mirror #{prefix}$X#{suffix} #{dest}/$X"
prepare = "mkdir -p #{dest}/$X; echo -n \"(\" $(date +%R) \")\""
system "cat #{config['list']} | while read X Y; do #{prepare}; #{cmds}; done"

