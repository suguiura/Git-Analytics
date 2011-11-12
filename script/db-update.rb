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

def create_person(name, email)
  Person.find_or_create_by_email(fix_email(email), :name => name)
end

signatures = "Signed-off-by|Reported-by|Reviewed-by|Tested-by|Acked-by|Cc"
$re_signatures = /^    (#{signatures}): (.* <(.+)>|.*)$/
def parse_signatures(line, commit)
  line.scan($re_signatures) do |key, name, email|
    data = {:name => key.downcase, :commit => commit}
    create_person(name, email || name).signatures.create(data)
  end
end

$re_changes = /^ (.+) \|\s+(\d+) /
def parse_changes(line, commit)
  line.scan($re_changes) do |path, changes|
    commit.modifications.create(:path => path, :linechanges => changes.to_i)
  end
end

$offset = Hash.new{|hash, key| hash[key] = -DateTime.parse('1970-01-01 00:00:00 ' + key).to_time.to_i}
$re_person = Hash.new{|hash, key| hash[key] = /^#{key} (.*) <(.*)> (.*) (.*)$/}
def parse_person(header, line)
  name, email, secs, offset = $re_person[header].match(line).captures
  [create_person(name.strip, email), Time.at(secs.to_i).utc, $offset[offset]]
end

$re_message = /^    (.*)$/
$re_commit = /^commit (\S+) ?(.*)$/
def parse(data, line)
  line = line.encode(Encoding::UTF_8, Encoding::ISO8859_1).rstrip
  sha1, tag = $re_commit.match(line).captures
  return if Commit.exists?(:sha1 => sha1)
  
  message = line.scan($re_message).join("\n").strip
  author, author_date, author_offset = parse_person('author', line)
  committer, committer_date, committer_offset = parse_person('committer', line)

  commit = Commit.create do |c|
    c.origin         = data[:origin]
    c.project        = data[:name]
    c.description    = data[:description]
    c.sha1           = sha1
    c.tag            = tag
    c.message        = message
    c.author         = author
    c.author_date    = author_date
    c.committer      = committer
    c.committer_date = committer_date
  end

  parse_signatures(line, commit)
  parse_changes(line, commit)
end

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

each_server_config("Updating database for ") do |server, config|
  ActiveRecord::Base.establish_connection config[:db]
  n, re_origin = $projects[server].size, Regexp.new(config[:origin][:regexp])
  default_origin = config[:origin][:default]
  $projects[server].each do |project, data| n -= 1
    git = "git --git-dir '#{data[:dir]}' log #{data[:range]} "
    data[:origin] = re_origin.match(project).captures.first rescue default_origin
    m = IO.popen(git + '--oneline | wc -l').read.to_i
    $l.info "%5d - %s; total: %d" % [n, project, m]
    IO.popen(git + "-z --decorate --stat --pretty=raw") do |io|
      io.each("\0"){|line| m = step_log(m, 1000); parse(data, line)}
    end
  end
  $l.info "Associating companies"
  Company.find_each do |company| domain = get_sld(company.homepage)
    condition = {:conditions => ['email like ?', "%@#{domain}"]}
    company.people = Person.find(:all, condition) unless domain.nil?
  end
  $l.info "Done"
end

