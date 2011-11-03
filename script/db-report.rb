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

def get_sld(host)
  return nil if host.nil?
  parts = host.split('.')
  parts.shift if parts.first == 'www'
  cctld = parts.pop unless $config[:cctlds].index(parts.last).nil?
  gtld = parts.pop unless $config[:gtlds].index(parts.last).nil?
  organization = parts.pop
  subdomain = parts
  return nil if organization.nil? or (gtld.nil? and cctld.nil?)
  [subdomain, organization, gtld, cctld].join(' ').squeeze(' ').strip.gsub(' ', '.')
end

def get_domain(company)
  unless company.homepage.nil?
    uri = URI.parse company.homepage.strip.gsub(/((\?|\`| ).*)|(\/+$)/, '')
    domain = get_sld(uri.host)
    return domain unless (uri.path != '') or domain.nil?
  end

  return nil if company.email.nil?
  return get_sld(company.email.split('@')[1])
end

companies = {}
Company.find_each do |company|
  domain = get_domain(company)
  next if domain.nil?
  companies[domain] ||= []
  companies[domain] << company
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
def selection(a, b)
  Hash[a.select{|k,v| b.has_key?(k)}]
end

def log(people, companies, title='', prefix='')
  $l.info "--- " + title
  $l.info prefix + "People: %d" % count(people)
  $l.info prefix + "SLDs: %d" % people.keys.size
  conflicts = get_conflicts(people, companies)
  $l.info prefix + "Conflicts: %d" % conflicts.size
  $l.info prefix + "list of conflicts:\n" + conflicts.keys.join("\n")
  $l.info prefix + "top 10 SLDs:\n" + people.sort{|x,y|y.last.size<=>x.last.size}[0,10].map{|k,v|"%d %s" % [v.size, k]}.join("\n")
end

com = get_com(companies)
$l.info "Companies, SLD, Conflicts"
$l.info [count(companies), companies.keys.size, count0(companies)].join(', ')
$l.info "Companies, .com SLD, Conflicts"
$l.info [count(com), com.keys.size, count0(com)].join(', ')

each_server_config("*** Reporting for ") do |server, config|
  Person.establish_connection config[:db]

  people = {}
  Person.find_each do |person| next if person.email.nil?
    a, b = person.email.split('@')
    domain = get_sld(b)
    people[domain] ||= []
    people[domain] << person
  end

  log(people, companies, 'all')
  log(selection(people, companies), companies, 'all CB', '(CB) ')
  people = get_com(people)
  log(people, companies, '.com')
  log(selection(people, companies), companies, '.com CB', '(CB) ')
end

