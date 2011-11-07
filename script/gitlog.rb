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

def get_person(header, line)
  regexp = Regexp.new("^#{header} (.*)<(.*)> (.*) (.*)$")
  line.scan(regexp).map do |name, email, secs, offset|
    offset = -DateTime.parse('1970-01-01 00:00:00 ' + offset).to_time.to_i
    { :name => name.strip,
      :email => email,
      :offset => offset,
      :utcdate => Time.at(secs.to_i).utc
    }
  end.last
end

def get_signatures(line)
  sigs = {}
  regexp = /(Signed-off-by|Reported-by|Reviewed-by|Tested-by|Acked-by|Cc): ([^\n]*)/
  line.scan(regexp) do |key, value| key.downcase!
    name, email = value.split('<', 2).map{|x|x.strip}
    name, email = email, name if email.nil?
    email, numb = email.split('>', 2)
    sigs[key] = (sigs[key] || []) << {:name => name, :email => email}
  end
  sigs
end

def parse(origin, project, description, line)
  commit, tag = line.scan(/^commit (\S+) ?(.*)$/).flatten
  message = line.scan(/^    (.*)/).join("\n").strip
  changes = Hash[line.scan(/^ (.+) \| \s*(\d+) /).map{|path, n| n.to_i}]
  {
    :origin => origin,
    :project => project,
    :description => description,
    :commit => commit,
    :tag => tag,
    :author => get_person('author', line),
    :committer => get_person('committer', line),
    :message => message,
    :signatures => get_signatures(line),
    :changes => changes
  }.to_yaml[5..-1] + "\0"
end

each_server_config("Logging for ") do |server, config|
  file = File.open(config[:data][:gitlog], 'w')
  n = $projects[server].size
  $projects[server].each do |project, data| n -= 1
    $l.info "%5d - %s" % [n, project]
    dir, range = data[:dir], data[:range]
    regexp = Regexp.new(config[:origin][:regexp])
    origin = project.scan(regexp).first || config[:origin][:default]
    git = "git --git-dir #{dir} log -z --decorate --stat --pretty=raw #{range}"
    IO.popen(git){|io| io.each("\0") do |line|
      file.write parse(origin, project, data[:description], line.rstrip)
    end}
  end
  $l.info "Done"
end

