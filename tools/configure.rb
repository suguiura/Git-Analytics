#!/usr/bin/env ruby

require 'logger'
require 'net/http'
require 'uri'
require 'xml'
require 'yaml'

load 'lib/utils.rb'

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

def load_origin(config, project)
  origin = config[:origin]
  regex, default = Regexp.new(origin[:regexp]), origin[:default]
  regex.match(project).captures.first rescue default
end

each_server_config("Configuring ") do |server, config, projects|
  paths = get_paths(server, config)
#  download_descriptions(server, config, paths)
  instances = config[:instances] || {}
  paths.each do |path, tmpfile|
    next if (config[:list][:deny] || []).include?(path)
    next unless projects[path].nil?
    description = (File.exists?(tmpfile) ? IO.read(tmpfile).strip : '')
    name = path.split('/').last.sub(/\.git$/, '')
    git, dir = config[:git][:url].join(path), config[:data][:dir].join(path)
    origin = load_origin(config, path)
    project = {path => {:fork        => false,
                        :origin      => origin,
                        :name        => name,
                        :description => description,
                        :range       => nil,
                        :dir         => dir,
                        :git         => git
                       }.update(instances[path] || {})}
    projects.update(project)
  end
end

File.new($config[:list], 'w').puts $projects.to_yaml
$l.info 'Done.'

