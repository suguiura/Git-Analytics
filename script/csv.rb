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

opts = ARGV.getopts("", "default-origin:", "regexp-origin:")

$cctlds = %w(ac ad ae af ag ai al am an ao aq ar as at au aw ax az ba bb bd be bf bg bh bi bj bm bn bo br bs bt bv bw by bz ca cc cd cf cg ch ci ck cl cm cn co cr cu cv cx cy cz de dj dk dm do dz ec ee eg er es et eu fi fj fk fm fo fr ga gb gd ge gf gg gh gi gl gm gn gp gq gr gs gt gu gw gy hk hm hn hr ht hu id ie il im in io iq ir is it je jm jo jp ke kg kh ki km kn kp kr kw ky kz la lb lc li lk lr ls lt lu lv ly ma mc md me mg mh mk ml mm mn mo mp mq mr ms mt mu mv mw mx my mz na nc ne nf ng ni nl no np nr nu nz om pa pe pf pg ph pk pl pm pn pr ps pt pw py qa re ro rs ru rw sa sb sc sd se sg sh si sj sk sl sm sn so sr st su sv sy sz tc td tf tg th tj tk tl tm tn to tp tr tt tv tw tz ua ug uk us uy uz va vc ve vg vi vn vu wf ws ye yt za zm zw)
$gtlds = %w(aero arpa asia biz cat com coop edu gov info int jobs mil mobi museum name net org pro tel travel xxx)

$tags8 = ["Signed-off-by", "Reported-by", "Reviewed-by", "Tested-by"]
$tags4 = ["Acked-by", "Cc"]

def cat_and_spawn(prefixes, array, n)
  prefixes.map{|prefix|(1..n).map{|x|([prefix + (n > 1 ? "[#{x}] " : ' ')] * array.size).zip(array).map{|y|y.join}}}
end

def header
  domain = (['domain'] * 5).zip(['', ' department', ' company', ' gtld', ' cctld']).map{|x| x.join}

  tags = [cat_and_spawn($tags8, [''] + domain, 8), cat_and_spawn($tags4, [''] + domain, 4)]

  attribs = ['name', 'email', domain, 'date'].flatten
  author, committer = cat_and_spawn(['author ', 'committer '], attribs, 1)

  ['origin', 'project', 'shortdesc', author, committer, 'committer_date - author_date (seconds)', 'tag', 'files changed', 'line insertions', 'line deletions', 'subject', 'subject length', 'body', 'body length', tags].join("\t")
end

def domain(email)
  domain = email.split('@', 2)[1] || ''
  parts = domain.split('.')
  cctld = parts.pop unless $cctlds.index(parts.last).nil?
  gtld = parts.pop unless $gtlds.index(parts.last).nil?
  company = parts.pop
  [domain, parts.join('.'), company, gtld, cctld]
end

def tag_email(str, queries, n)
  queries.map{|query|(str.scan(Regexp.new(query + ": [^<]*<([^>]*)>")).flatten.map{|x| y = x.strip; [y, domain(y)]}.flatten + Array.new(6 * n, ''))[0, 6 * n]}
end

def tags(body)
  [tag_email(body, $tags8, 8), tag_email(body, $tags4, 4)]
end

def stats(shortstat)
  (shortstat.scan(/(\d+)/).map{|x| x.first} + [0, 0, 0]).first(3)
end

puts header
STDIN.each_line("\0") do |line|
  next if line.strip.empty?
  # check the header function for variables description
  pr, sd, an, ae, ai, cn, ce, ci, r, s, b, ss = line.split("\t").map{|x| x.strip || ''}
  origin = pr.scan(Regexp.new(opts['regexp-origin'])).first unless opts['regexp-origin'].nil?
  origin ||= opts['default-origin'] || ''
  td = (Time.parse(ci) - Time.parse(ai)).to_i
  b = b.dump[1..-2]
  puts [origin, pr, sd, an, ae, domain(ae), ai, cn, ce, domain(ce), ci, td, r[1..-2], stats(ss), s, s.size, b, b.size, tags(b)].join("\t")
end

