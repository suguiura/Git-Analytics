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

require 'yaml'
require 'time'
require 'optparse'

$: << File.join(File.dirname(__FILE__), '.')
require 'config'

$tags8 = ["Signed-off-by", "Reported-by", "Reviewed-by", "Tested-by"]
$tags4 = ["Acked-by", "Cc"]

def cat_and_spawn(array, suffixes, n)
  array.map do |x|
    (1..n).map do |y|
      clones = [x + (n > 1 ? "[#{y}] " : ' ')] * suffixes.size
      clones.zip(suffixes).map{|z|z.join}
    end
  end
end

def header
  email_suffixes = ['', ' domain', ' department', ' company', ' gtld', ' cctld']
  email = (['email'] * 6).zip(email_suffixes).map{|x| x.join}
  attribs = ['name', email, 'date'].flatten
  author, committer = cat_and_spawn(['author', 'committer'], attribs, 1)
  tags = [cat_and_spawn($tags8, email, 8), cat_and_spawn($tags4, email, 4)]
  files = [cat_and_spawn(['file'], [''], 100)]

  ['origin', 'project', 'shortdesc', author, committer, 'committer_date - author_date (seconds)', 'commit tag', 'message', 'message length', 'file changes', 'line changes', files, tags].join("\t")
end

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

def parse_email(email)
  email = fix_email(email)
  domain = email.split('@', 2)[1] || ''
  parts = domain.split('.')
  cctld = parts.pop unless $config[:cctlds].index(parts.last).nil?
  gtld = parts.pop unless $config[:gtlds].index(parts.last).nil?
  company = parts.pop
  [email, domain, parts.join('.'), company, gtld, cctld]
end

def parse_person(person)
  name, email, date = person.scan(/(.*)<(.*)>(.*)/).flatten.map{|x|x.strip}
  [name, parse_email(email), parse_date(date)]
end

def tag_email(str, queries, n)
  queries.map do |query|
    array = str.scan(Regexp.new(query + ": [^<]*<([^>]*)>")).flatten
    array = array.map{|x| y = x.strip; [parse_email(y)]}.flatten
    (array + Array.new(6 * n, ''))[0, 6 * n]
  end
end

each_server_config do |server, config|
  $l.info "Generating CSV for #{server}"
  gitlog, output = config[:data][:gitlog], File.open(config[:data][:csv], 'w')
  output.puts header
  half = n = %x(cat #{gitlog} | tr -dc "\\0" | wc -c).to_i + 1
  IO.foreach(gitlog, "\0") do |line| n -= 1
    if n <= half
      $l.info "#{n} commit(s) left"
      half /= 2
    end
    line.strip!;
    next if line.empty?
    line.gsub!(/^(path|description|commit|tree|parent|author|committer) /, ":\\1: |-\n  ")
    line.sub!(/\n\n (\S)/, "\n:changes: |-\n \\1")
    line.sub!(/\n\n    /, "\n:message: |-\n    \t")
    line.gsub!(/(\n    \n)(    \n)*/, '\1')
    data = YAML.load line
    unless data[:path].nil?
      $path, $description = data[:path], data[:description]
      regexp = Regexp.new(config[:origin][:regexp] || '^$')
      $origin = $path.scan(regexp).first || config[:origin][:default] || '.'
    else
      author = parse_person(data[:author])
      committer = parse_person(data[:committer])
      committag = data[:commit].split(' ', 2)[1]
      message = (data[:message] || '').strip.dump[1..-2]
      changes = (data[:changes] || '').split("\n")[0..-2]
      linechanges = changes.map{|x| x.split('|', 2).last.to_i}
      filechanges = changes.map{|x| x.split('|', 2).first.strip}
      
      output.puts [$origin, $path, $description, author, committer,
            committer[3].to_i - author[3].to_i,
            committag, message, message.size,
            filechanges.compact.size, linechanges.compact.size,
            (filechanges + [nil] * 100)[0, 100],
            tag_email(message, $tags8, 8),
            tag_email(message, $tags4, 4)
           ].join("\t")
    end
  end
end

