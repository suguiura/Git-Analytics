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

$: << File.dirname(__FILE__)
require 'config'
require 'uri'

$l.info 'Start'

def get_domain(host)
  return nil if host.nil?
  parts = host.split('.')
  parts.shift if parts.first == 'www'
  cctld = parts.pop unless $config[:cctlds].index(parts.last).nil?
  gtld = parts.pop unless $config[:gtlds].index(parts.last).nil?
  company = parts.pop
  department = parts
  return nil if company.nil? or (gtld.nil? and cctld.nil?)
  [department, company, gtld, cctld].join(' ').squeeze(' ').strip.gsub(' ', '.')
end

companies_by_homepage = {}
companies_by_email = {}
companies = {}
Company.find_each do |company|
  homepage = company.homepage.strip.gsub(/(\?|\`| ).*/, '').gsub(/\/+$/, '') unless company.homepage.nil?
  uri = URI.parse(homepage || '')
  a, b = company.email.split('@') unless company.email.nil?

  homepage_domain = get_domain(uri.host) unless (uri.path != '')
  companies_by_homepage[homepage_domain] ||= []
  companies_by_homepage[homepage_domain] << company
  email_domain = get_domain(b)
  companies_by_email[email_domain] ||= []
  companies_by_email[email_domain] << company
  if homepage_domain == email_domain
    companies[homepage_domain] ||= []
    companies[homepage_domain] << company
  end
end

$l.info 'Queries gathered'

def count(h)
  h.values.inject(0){|memo,list| memo + list.size}
end
def count0(h)
  h.values.inject(0){|memo,list| memo + (list.size == 1 ? 0 : list.size)}
end
def get_conflicts(g, h)
  Hash[g.select{|k,v| h.has_key?(k) and h[k].size > 1}]
end
def get_com(g)
  Hash[g.select{|k,v| (not k.nil?) and k.end_with?('.com')}]
end

com = get_com(companies)
$l.info "Companies (domains): %d (%d)" % [count(companies), companies.keys.size]
$l.info "Conflicts: %d" % count0(companies)
$l.info "Companies (domains.com): %d (%d)" % [count(com), com.keys.size]
$l.info "Conflicts: %d" % count0(com)

servers = ARGV.map{|x| x.to_sym} & $config[:servers].keys
servers = $config[:servers].keys if servers.empty?
servers.each do |server| config = $config[:servers][server]
  $stderr.puts
  $l.info "Reporting for #{server}"
  Person.establish_connection config[:db]

  people_by_email = {}
  Person.find_each do |person| next if person.email.nil?
    a, b = person.email.split('@')
    domain = get_domain(b)
    people_by_email[domain] ||= []
    people_by_email[domain] << person
  end

  conflicts = get_conflicts(people_by_email, companies)
  common = (people_by_email.keys & companies.keys)
  com = get_com(people_by_email)

  $l.info "People (domains): %d (%d)" % [count(people_by_email), people_by_email.keys.size]
  $l.info "Conflicts: %d" % conflicts.size
  $l.info "People domains in CB: %d" % common.size
  $l.info "list of conflicts:\n%s" % conflicts.keys.join("\n")
  $l.info "People (domains.com): %d (%d)" % [count(com), com.keys.size]
end

