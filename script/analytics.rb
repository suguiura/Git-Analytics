#!/usr/bin/env ruby

$: << File.dirname(__FILE__)
require 'config'
require 'git'
require 'db'
require 'schema'
require 'gcsv'
require 'uri'

$l.info "Start"

gtld = '(%s)' % $config[:gtlds].join('|')
cctld = '(%s)' % $config[:cctlds].join('|')
$re_tld = /\.(#{gtld}\.#{cctld}|#{gtld}|#{cctld})$/
$re_host = /^www\./
def get_sld(homepage)
  uri = URI.parse homepage rescue return
  return if uri.path.length > 1
  host = uri.host.sub($re_host, '') rescue return
  host if host =~ $re_tld
end

def associate_companies()
  n = Company.count
  $l.info "Associating companies (#{n})"
  Company.find_each do |company| domain = get_sld(company.homepage)
    n = step_log(n, 1000, '', " companies left")
    condition = {:conditions => ['email like ?', "%@#{domain}"]}
    company.authors = Author.find(:all, condition) unless domain.nil?
  end
end

def process_project(data)
  dir, range = data[:dir], data[:range]
  extra = {:origin      => data[:origin],
           :project     => data[:name],
           :description => data[:description]}
  n = GitAnalytics::Git.count(dir, range)
  $l.info "total: %d" % n
  GitAnalytics::Git.log(dir, range, extra) do |log|
    n = step_log(n, 1000, 'commits: ')
#    GitAnalytics::DB.store(log)
    GitAnalytics::GCSV.store(log)
  end
  $l.info "done"
end

def process_server(server, config, projects)
  n = projects.size
  projects.each do |project, data|
    n = step_log(n, 1, '', " - #{project}")
    GitAnalytics::GCSV.open(config[:data][:csv])
    process_project(data)
  end
end

each_server_config "Processing " do |server, config, projects|
#  GitAnalytics::Schema.create_tables
#  GitAnalytics::Schema.remove_indexes
#  GitAnalytics::Schema.add_indexes
  process_server(server, config, projects)
#  associate_companies
end

$l.info "Finish!"
