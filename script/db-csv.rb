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

puts header

def fill_array(array, totalfields, fieldsize=1)
  (array + [[nil] * fieldsize] * totalfields)[0, totalfields]
end

def split_email(email)
  username, domain = (email + '@').split('@', 3)
  parts = domain.split('.')
  cctld = parts.pop unless $config[:global][:cctlds].index(parts.last).nil?
  gtld = parts.pop unless $config[:global][:gtlds].index(parts.last).nil?
  company = parts.pop
  [email, domain, parts.join('.'), company, gtld, cctld]
end

servers = ARGV.map{|x| x.to_sym} & $config[:servers].keys
servers = $config[:servers].keys if servers.empty?
servers.each do |server| config = $config[:servers][server]
  $l.info "Generating CSV for for #{server}"
  ActiveRecord::Base.establish_connection config[:db]
  Commit.find_each do |commit|
    puts [
      commit.origin,
      commit.project,
      commit.description,
      commit.author.name,
      split_email(commit.author.email),
      commit.author_date,
      commit.committer.name,
      split_email(commit.committer.email),
      commit.committer_date,
      commit.committer_date.to_i - commit.author_date.to_i,
      commit.tag,
      commit.message,
      commit.message.length,
      commit.modifications.length,
      commit.modifications.inject(0){|memo, x| memo + x.linechanges},
      fill_array(commit.modifications.map{|x| x.path}, 100),
      fill_array(commit.signatures.map{|s|split_email(s.person.email)}, 8, 6)
    ].join "\t"
  end
end
