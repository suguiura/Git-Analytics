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
require 'optparse'

config = YAML.load_file(ARGV.first)

regexp = Regexp.new(config[:list][:regexp])
paths = unless config[:list][:only].nil?
  config[:list][:only]
else
  STDERR.puts 'Downloading list'
  result = Net::HTTP.get URI.parse config[:list][:url]
  result.strip.split("\n").map{|x| x.strip.scan(regexp).first}
end

filename = ["/tmp/description-#{config[:host]}-", ".txt"]
xpath, nslist = config[:description][:find].values
paths.each_index do |i| path = paths[i]
  next if File.exists? filename.join(i.to_s)
  STDERR.puts 'Downloading description for ' + path
  Process.fork do
    xml = Net::HTTP.get URI.parse config[:description][:url].join(path)
    description = XML::Parser.string(xml).parse.find_first(xpath, nslist).first
    File.new(filename.join(i.to_s), 'w').write "#{path} #{description}"
  end
  sleep 1
end
STDERR.puts 'Waiting processes'
Process.waitall

descriptions = Hash[paths.each_index.map do |i|
  File.open(filename.join(i.to_s)).read.strip.split ' ', 2
end]

STDERR.puts 'Generating ' + config[:list][:file]

file = File.new config[:list][:file], 'w'
paths.each do |path|
  next unless (config[:list][:deny] || []).index(path).nil?
  project = {:path => path, :fork => false, :range => nil,
             :name => path.split('/').last.sub(/\.git$/, ''),
             :dir => config[:data][:dir].join(path),
             :git => config[:git][:url].join(path),
             :description => descriptions[path]}
  project.update(config[:instances][path] || {}) if config[:instances]
  file.puts [project].to_yaml[5..-1]
end

STDERR.puts 'Done.'

