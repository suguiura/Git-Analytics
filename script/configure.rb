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

$config = YAML.load_file('config/servers.yaml')

servers = $config[:servers].keys
servers &= ARGV.map{|x| x.to_sym} unless ARGV.empty?

def download_descriptions(config, server, paths)
  filename = ["/tmp/description-#{server}-", ".txt"]
  xpath, nslist = config[:description][:find].values
  paths.each_index do |i| path = paths[i]
    next if File.exists? filename.join(i.to_s)
    STDERR.puts "Downloading description for #{path}..."
    Process.fork do
      xml = Net::HTTP.get URI.parse config[:description][:url].join(path)
      description = XML::Parser.string(xml).parse.find_first(xpath, nslist).first
      File.new(filename.join(i.to_s), 'w').write "#{path} #{description}"
    end
    sleep 1
  end
  STDERR.puts 'Waiting download processes to finish...'
  Process.waitall

  Hash[paths.each_index.map do |i|
    File.open(filename.join(i.to_s)).read.strip.split ' ', 2
  end]
end

def get_paths(config)
  unless config[:list][:only].nil?
    config[:list][:only]
  else
    url = config[:list][:url]
    STDERR.puts "Downloading list from #{url}..."
    result = Net::HTTP.get URI.parse url
    regexp = Regexp.new(config[:list][:regexp])
    result.strip.split("\n").map{|x| x.strip.scan(regexp).first}
  end
end

listfilename = $config[:global][:list][:file]
system "mkdir -p $(dirname #{listfilename}); touch #{listfilename}"
list = (YAML.load_file(listfilename) || {})

servers.each do |server| config = $config[:servers][server]
  paths = get_paths(config)
  descriptions = download_descriptions(config, server, paths)

  STDERR.puts 'Gathering information...'
  list[server] ||= {}
  paths.each do |path|
    next if (config[:list][:deny] || []).include?(path)
    next unless list[server][path].nil?
    list[server][path] = {
      :fork => false, :range => nil,
      :name => path.split('/').last.sub(/\.git$/, ''),
      :dir => config[:data][:dir].join(path),
      :git => config[:git][:url].join(path),
      :description => descriptions[path]
      }.update((config[:instances] || {})[path] || {})
  end
end

STDERR.puts 'Writting to file...'
File.new(listfilename, 'w').puts list.to_yaml
STDERR.puts 'Done.'

