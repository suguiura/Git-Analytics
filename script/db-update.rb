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

$: << File.dirname(__FILE__)
require 'config'

emailfixfile = $config[:global][:emailfix][:file]
system "mkdir -p $(dirname #{emailfixfile}); touch #{emailfixfile}"
$emailfixmap = YAML.load_file(emailfixfile) || {}

def offset_seconds(offset)
  number = offset.to_i
  return 0 if number == 0
  hours, minutes = offset.scan(/^(.*)(..)$/).flatten.map{|x|x.to_i}
  (number / number.abs) * (hours.abs * 3600 + minutes * 60)
end

def parse_date(date)
  secs, offset = date.split
  time = Time.at(secs.to_i) + offset_seconds(offset)
  time.strftime('%Y-%m-%d %H:%M:%S ' + offset)
end

def create_person(name, email)
  email = $emailfixmap[email] || email || ''
  Person.find_or_create_by_email(email, :name => name)
end

def parse_person_date(data)
  name, email, date = data.scan(/(.*)<(.*)>(.*)/).flatten.map{|x|x.strip}
  [create_person(name, email), parse_date(date)]
end

def parse_signatures(message)
  signatures = ["Signed-off-by", "Reported-by", "Reviewed-by", "Tested-by",
          "Acked-by", "Cc"].join('|')
  regexp = Regexp.new("(#{signatures}): ([^<]*)<([^>]*)>")
  message.scan(regexp).map do |signature, name, email|
    create_person(name, email).signatures.find_or_create_by_name(signature)
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
  author,    author_date    = parse_person_date(data[:author])
  committer, committer_date = parse_person_date(data[:committer])
  sha1, tag = data[:commit].split(' ', 2)
  message   = (data[:message] || '').strip

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

each_config_server do |server, config|
  $l.info "Updating database for #{server}"
  ActiveRecord::Base.establish_connection config[:db]
  gitlog = config[:data][:gitlog]
  n = %x(cat #{gitlog} | tr -dc "\\0" | wc -c).to_i + 1
  $l.info "Total: #{n} commit(s)"
  IO.foreach(gitlog, "\0") do |line| n -= 1
    $l.info "#{n} commit(s) left" if (n % 1000) == 0
    line.strip!
    next if line.empty?
    line.gsub!(/^(path|description|commit|tree|parent|author|committer) /, ":\\1: |-\n  ")
    line.sub!(/\n\n (\S)/, "\n:changes: |-\n \\1")
    line.sub!(/\n\n    /, "\n:message: |-\n    \t")
    line.gsub!(/(\n    \n)(    \n)*/, '\1')
    parse_data config, YAML.load(line)
  end

  Company.find_each do |company| domain = get_sld(company.homepage)
    company.people = Person.find(:all, {:conditions => ['email like ?', "%@#{domain}"]}) unless domain.nil?
  end
end

