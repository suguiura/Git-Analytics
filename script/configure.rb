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

require 'net/http'
require 'uri'
require 'xml'

$: << File.join(File.dirname(__FILE__), '.')
require 'config'

def download_descriptions(server, config, paths)
  $l.info "Downloading description for:"
  xpath, nslist = config[:description][:find].values
  n = paths.size
  paths.each do |path, tmpfile| n -= 1
    $l.info "%5d - %s" % (n, path)
    next if File.exists? tmpfile
    Process.fork do
      xml = Net::HTTP.get URI.parse config[:description][:url].join(path)
      description = XML::Parser.string(xml).parse.find_first(xpath, nslist).first
      File.new(tmpfile, 'w').write description
    end; sleep 1
  end
  $l.info 'Waiting download processes to finish...'; Process.waitall
end

def get_paths(server, config)
  filename = ["/tmp/description-#{server}-", ".txt"]
  unless config[:list][:only].nil?
    config[:list][:only]
  else
    url = config[:list][:url]
    $l.info "Downloading list from #{url}..."
    result = Net::HTTP.get URI.parse url
    regexp = Regexp.new(config[:list][:regexp])
    result.strip.split("\n").map{|x| x.strip.scan(regexp).first}
  end.inject({}) do |hash, path|
    tmpfile = filename.join(path.hash.to_s.tr('-', 'x'))
    hash.update({path => tmpfile})
  end
end

servers = ARGV.map{|x| x.to_sym} & $config[:servers].keys
servers = $config[:servers].keys if servers.empty?
servers.each do |server| $l.info "Configuring #{server}"
  config = $config[:servers][server]
  paths = get_paths(server, config)
  download_descriptions(server, config, paths)
  $projects[server] ||= {}
  paths.each do |path, tmpfile|
    next if (config[:list][:deny] || []).include?(path)
    next unless $projects[server][path].nil?
    description = (File.exists?(tmpfile) ? IO.read(tmpfile).strip : '')
    name = path.split('/').last.sub(/\.git$/, '')
    git, dir = config[:git][:url].join(path), config[:data][:dir].join(path)
    project = {path => {:name => name, :fork => false, :range => nil,
                        :description => description, :dir => dir, :git => git
                       }.update((config[:instances] || {})[path] || {})}
    $projects[server].update(project)
  end
end

File.new($config[:global][:list][:file], 'w').puts $projects.to_yaml
$l.info 'Done.'

