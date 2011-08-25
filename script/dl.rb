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

list = config['file-project-list']
listurl = config['url-project-list']

wget = "wget -O - '#{listurl}' | #{config['url-project-list-parser']} > #{list}"
system "echo 'Downloading list...'; #{wget}" if not File.exists? list

dir = "#{config['dir-project-prefix']}$X#{config['dir-project-suffix']}"
url = "#{config['url-git-prefix']}$X#{config['url-git-suffix']}"
cmd = "git clone --mirror #{url} #{dir}"
prepare = "mkdir -p #{dir}; echo '('$(date +%R)')'"
system "cat #{list} | while read X; do #{prepare}; #{cmd}; done"

