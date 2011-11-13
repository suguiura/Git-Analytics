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

require 'uri'

$: << File.dirname(__FILE__)
require 'config'
require 'git'
require 'db'
require 'schema'

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
  $l.info "Associating companies"
  Company.find_each do |company| domain = get_sld(company.homepage)
    condition = {:conditions => ['email like ?', "%@#{domain}"]}
    company.authors = Author.find(:all, condition) unless domain.nil?
  end
  $l.info "Done"
end

def process_project(data)
  m = GitAnalytics::Git.count(data[:dir], data[:range])

  $l.info "total: %d" % m
  GitAnalytics::Git.log(data[:dir], data[:range]) do |log|
    m = step_log(m, 1000, 'commits: ')
    log[:origin] = data[:origin]
    log[:name] = data[:name]
    log[:description] = data[:description]
    GitAnalytics::DB.store(log)
  end
end

def load_origin(config, project)
  origin = config[:origin]
  regex, default = Regexp.new(origin[:regexp]), origin[:default]
  regex.match(project).captures.first rescue default
end

each_server_config "Updating database for " do |server, config|
  GitAnalytics::Schema.create_tables
  GitAnalytics::Schema.add_indexes
  n = $projects[server].size rescue next
  $projects[server].each do |project, data|
    n = step_log(n, 1, '', " - #{project}")
    data[:origin] = load_origin(config, project)
    process_project(data)
  end
#  associate_companies
end

