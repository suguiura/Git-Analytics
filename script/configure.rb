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

config = YAML::load(File.open(ARGV.first))
opts = ARGV.getopts('', 'stdin')

regexp = Regexp.new(config[:list][:regexp])
projects = if opts['stdin']
  STDERR.puts 'Downloading list'
  ARGF.read
else
  Net::HTTP.get URI.parse config[:list][:url]
end.strip.split("\n").map{|x| x.strip.scan(regexp).first}

xpath, nslist = config[:description][:find].values
puts projects.map do |project|
  STDERR.puts 'Downloading description for ' + project
  xml = Net::HTTP.get URI.parse config[:description][:url].join(project)
  description = XML::Parser.string(xml).parse.find_first(xpath, nslist).first
  {:project => project,
   :description => description,
   :git => config[:git][:url].join(project),
   :dir => config[:data][:dir].join(project)}
end.to_yaml

