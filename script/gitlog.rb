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

def format(project, description)
  vars = %w(%an %aE %ai %cn %cE %ci %d %s %b).join('%x09')
  "--format=\"%x00#{project}%x09#{description}%x09" + vars + "%x09\""
end

list = config['file-project-list']

dir = "#{config['dir-project-prefix']}/$X#{config['dir-project-suffix']}"
cmd = "git --git-dir #{dir} log #{format('$X', '$D')} --shortstat"
system "cat #{list} | while read X; do D=$(cat #{dir}/description); #{cmd}; done"

