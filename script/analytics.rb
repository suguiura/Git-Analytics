#!/usr/bin/env ruby

$: << File.dirname(__FILE__)
require 'config'
require 'git'
require 'db'
require 'schema'
require 'gcsv'
require 'uri'

$l.info "Start"

def process_project(data)
  dir, range = data[:dir], data[:range]
  extra = {:server      => data[:server],
           :origin      => data[:origin],
           :project     => data[:name],
           :description => data[:description]}
  n = GitAnalytics::Git.count(dir, range)
  $l.info "total: %d" % n
  GitAnalytics::Git.log(dir, range, extra) do |log|
    n = step_log(n, 1000, 'commits: ')
    GitAnalytics::DB.store(log)
    GitAnalytics::GCSV.store(log)
  end
  $l.info "done"
end

GitAnalytics::Schema.create_tables
#GitAnalytics::Schema.remove_indexes
GitAnalytics::Schema.add_indexes
each_server_config "Processing " do |server, config, projects|
  n = projects.size
  projects.each do |project, data|
    n = step_log(n, 1, '', " - #{project}")
    GitAnalytics::GCSV.open(config[:data][:csv])
    process_project(data)
  end
end

$l.info "Finish!"
