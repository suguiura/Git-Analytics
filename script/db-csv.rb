#!/usr/bin/env ruby

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
  attribs = ['name', email, 'cb permalink', 'date'].flatten
  author, committer = cat_and_spawn(['author', 'committer'], attribs, 1)
  tags = [cat_and_spawn($tags8, email, 8), cat_and_spawn($tags4, email, 4)]
  files = [cat_and_spawn(['file'], [''], 100)]

  ['origin', 'project', 'description', author, committer, 'committer_date - author_date (seconds)', 'commit tag', 'message', 'message length', 'file changes', 'line changes', files, tags].join("\t")
end

def fill_array(array, totalfields, fieldsize=1)
  (array + [[nil] * fieldsize] * totalfields)[0, totalfields]
end

def split_email(email)
  username, domain = (email + '@').split('@', 3)
  parts = domain.split('.')
  cctld = parts.pop unless $config[:cctlds].index(parts.last).nil?
  gtld = parts.pop unless $config[:gtlds].index(parts.last).nil?
  company = parts.pop
  [email, domain, parts.join('.'), company, gtld, cctld]
end

each_server_config("Generating CSV for for ") do |server, config|
  file = File.open(config[:data][:csv], 'w')
  file.puts header
  n = Commit.count
  $l.info "Total: #{n} commit(s)"
  Commit.find_each do |commit| n -= 1
    $l.info "#{n} commit(s) left" if (n % 1000) == 0
    file.puts [
      commit.origin,
      commit.project,
      commit.description,
      commit.author.name,
      split_email(commit.author.email),
      (commit.author.company.permalink rescue ''),
      commit.author_date,
      commit.committer.name,
      split_email(commit.committer.email),
      (commit.committer.company.permalink rescue ''),
      commit.committer_date,
      commit.committer_date.to_i - commit.author_date.to_i,
      commit.tag,
      commit.message,
      commit.message.length,
      commit.modifications.count,
      commit.modifications.inject(0){|memo, x| memo + x.linechanges},
      fill_array(commit.modifications.map{|x| x.path}, 100),
      fill_array(commit.signatures.map{|s|split_email(s.person.email)}, 8, 6)
    ].join "\t"
  end
end

