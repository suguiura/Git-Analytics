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

require 'time'
require 'optparse'
require 'uri'

$: << File.dirname(__FILE__)
require 'config'

def offset_seconds(offset)
  number = offset.to_i
  return 0 if number == 0
  hours, minutes = offset.scan(/^(.*)(..)$/).flatten.map{|x|x.to_i}
  (number / number.abs) * (hours.abs * 3600 + minutes * 60)
end

def parse_date(date)
  secs, offset = date.split
  Time.at(secs.to_i + offset_seconds(offset)).utc.strftime('%Y-%m-%d %H:%M:%S')
end

def create_person(name, email)
  Person.find_or_create_by_email(fix_email(email), :name => name)
end

def parse_person_date(data)
  name, email, date = data.scan(/(.*)<(.*)>(.*)/).flatten.map{|x|x.strip}
  [create_person(name, email), parse_date(date)]
end

def parse_signatures(message)
  signatures = ["Signed-off-by", "Reported-by", "Reviewed-by", "Tested-by",
          "Acked-by", "Cc"].join('|')
  regexp = Regexp.new("(#{signatures}): ([^<]*)<([^>\n]*)>")
  message.scan(regexp).map do |signature, name, email|
    create_person(name, email).signatures.create(:name => signature)
  end
end

def parse_changes(data)
  (data || '').split("\n")[0..-2].map do |entry|
    path, changes = entry.split('|', 2)
    Modification.create(:path => path, :linechanges => changes.to_i)
  end
end

def parse_data(config, data)
  unless data[:path].nil?
    $path        = data[:path]
    $description = data[:description]
    regexp       = Regexp.new(config[:origin][:regexp] || '^$')
    $origin      = $path.scan(regexp).first || config[:origin][:default] || '.'
    return
  end

  sha1, tag = data[:commit].split(' ', 2)
  message   = (data[:message] || '').strip
  author,    author_date    = parse_person_date(data[:author])
  committer, committer_date = parse_person_date(data[:committer])

  commit = Commit.create do |c|
    c.origin         = $origin
    c.project        = $path
    c.description    = $description
    c.sha1           = sha1
    c.tag            = tag
    c.message        = message.dump[1..-2]
    c.author         = author
    c.author_date    = author_date
    c.committer      = committer
    c.committer_date = committer_date
  end

  commit.signatures    << parse_signatures(message)
  commit.modifications << parse_changes(data[:changes])
end

def get_sld(homepage)
  return nil if homepage.nil?
  uri = URI.parse homepage.strip.gsub(/((\?|\`| ).*)|(\/+$)/, '')
  return nil if uri.path == '' or uri.host.nil?
  parts = uri.host.split('.')
  parts.shift if parts.first == 'www'
  cctld = parts.pop unless $config[:cctlds].index(parts.last).nil?
  gtld = parts.pop unless $config[:gtlds].index(parts.last).nil?
  organization = parts.pop
  department = parts
  return nil if organization.nil? or (gtld.nil? and cctld.nil?)
  [department, organization, gtld, cctld].join(' ').squeeze(' ').strip.gsub(' ', '.')
end

each_server_config("Updating database for ") do |server, config| last = Time.now
  ActiveRecord::Base.establish_connection config[:db]
  n = %x(cat #{config[:data][:gitlog]} | tr -dc "\\0" | wc -c).to_i + 1
  $l.info "Total: #{n} commit(s)"
  IO.foreach(config[:data][:gitlog], "\0") do |line| line.strip!
    n, last = step_log(n, last, 1000)
    parse_data(config, YAML.load(line)) unless line.empty?
  end

  $l.info "Associating companies"
  Company.find_each do |company| domain = get_sld(company.homepage)
    condition = {:conditions => ['email like ?', "%@#{domain}"]}
    company.people = Person.find(:all, condition) unless domain.nil?
  end
  $l.info "Done"
end

