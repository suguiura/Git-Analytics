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
require 'net/http'
require 'uri'
require 'xml'

$config = YAML.load_file('config.yaml')
argservers = ARGV.map{|x| x.to_sym}

def download_descriptions(server, config, paths)
  STDERR.puts "Downloading description for:"
  xpath, nslist = config[:description][:find].values
  n = paths.size
  paths.each do |path, tmpfile| n -= 1
    STDERR.printf "[%s] %5d - %s\n", Time.now.strftime("%H:%M:%S"), n, path
    next if File.exists? tmpfile
    Process.fork do
      xml = Net::HTTP.get URI.parse config[:description][:url].join(path)
      description = XML::Parser.string(xml).parse.find_first(xpath, nslist).first
      File.new(tmpfile, 'w').write description
    end; sleep 1
  end
  STDERR.puts 'Waiting download processes to finish...'; Process.waitall
end

def get_paths(server, config)
  filename = ["/tmp/description-#{server}-", ".txt"]
  unless config[:list][:only].nil?
    config[:list][:only]
  else
    url = config[:list][:url]
    STDERR.puts "Downloading list from #{url}..."
    result = Net::HTTP.get URI.parse url
    regexp = Regexp.new(config[:list][:regexp])
    result.strip.split("\n").map{|x| x.strip.scan(regexp).first}
  end.inject({}) do |hash, path|
    tmpfile = filename.join(path.hash.to_s.tr('-', 'x'))
    hash.update({path => tmpfile})
  end
end

listfilename = $config[:global][:list][:file]
system "mkdir -p $(dirname #{listfilename}); touch #{listfilename}"
list = (YAML.load_file(listfilename) || {})

$config[:servers].each do |server, config|
  next unless argservers.empty? or argservers.include? server
  STDERR.puts "Configuring #{server}"

  paths = get_paths(server, config)
  download_descriptions(server, config, paths)
  list[server] ||= {}
  paths.each do |path, tmpfile|
    next if (config[:list][:deny] || []).include?(path)
    next unless list[server][path].nil?
    description = (File.exists?(tmpfile) ? IO.read(tmpfile).strip : '')
    name = path.split('/').last.sub(/\.git$/, '')
    git, dir = config[:git][:url].join(path), config[:data][:dir].join(path)
    project = {path => {:name => name, :fork => false, :range => nil,
                        :description => description, :dir => dir, :git => git
                       }.update((config[:instances] || {})[path] || {})}
    list[server].update(project)
  end
end

File.new(listfilename, 'w').puts list.to_yaml
STDERR.puts 'Done.'

