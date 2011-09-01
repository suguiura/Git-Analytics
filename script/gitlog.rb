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

$config = YAML.load_file('config/servers.yaml')

servers = $config[:servers].keys
servers &= ARGV.map{|x| x.to_sym} unless ARGV.empty?

projects = YAML.load_file $config[:global][:list][:file]

servers.each do |server| n = projects[server].size
  STDERR.puts "Logging for #{server}..."
  counter = 0
  gitlog = File.open $config[:servers][server][:data][:gitlog], 'w'
  projects[server].each do |path, project| n -= 1
    STDERR.printf "[#{Time.now.strftime("%H:%M:%S")}] %5d - %s\n", n, path
    dir, range = project[:dir], project[:range]
    description = (project[:description] || "''").dump[1..-2]
    git = "git --git-dir #{dir} log -z --decorate --stat --pretty=raw #{range}"
    IO.popen git do |io|
      gitlog.write "\0path #{path}\ndescription #{description}\n\0"
      io.each("\0"){|line| gitlog.write(line); counter += 1}
    end
  end
  STDERR.puts "#{server} has #{counter} commits"
end

