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

$: << File.join(File.dirname(__FILE__), '.')
require 'config'

argservers = ARGV.map{|x| x.to_sym}

$config[:servers].each do |server, config|
  next unless argservers.empty? or argservers.include? server
  STDERR.puts "Downloading projects for #{server}..."
  n = $projects[server].size
  $projects[server].each do |path, project| n -= 1
    STDERR.printf "[%s] %5d - %s\n", Time.now.strftime("%H:%M:%S"), n, path
    name, dir, url = project[:name], project[:dir], project[:git]
    case
    when project[:fork]
      system "git --git-dir=#{dir} remote add #{name} #{url}"
    when !File.exists?(dir)
      system "mkdir -p #{dir}; git clone --mirror #{url} #{dir}"
    end
    # --prune removes project forks, should be avoided
    system "git --git-dir=#{dir} remote update"
  end
end

