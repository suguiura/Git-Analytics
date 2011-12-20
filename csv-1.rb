#!/usr/bin/env ruby

require 'yaml'
require 'logger'
require 'active_record'

load 'lib/db.rb'

$l = Logger.new STDERR
$l.formatter = Logger::Formatter.new

$config = YAML::load_file 'config.yaml'

def process(commit, type, company, other_company)
  a, b = company, other_company
  a_permalink = a.permalink rescue ''
  b_permalink = b.permalink rescue ''
  competition = a.competitors.include?(b) rescue false
  counter = a.similarities.find_or_create_by_other_company(b).counter rescue 0
  similarity = counter.to_f / a.tags.size rescue 0.0
  puts [
    commit.project.server.name,
    commit.project.origin,
    commit.project.name,
    commit.project.description,
    a_permalink,
    b_permalink,
    commit.author_date,
    commit.committer_date,
    commit.modifications.size,
    type,
    competition,
    similarity
  ].join("\t")
end

puts %w(server origin project description org1 org2 author_date commit_date
        filechanges relationship competition tag_similarity)

GitAnalytics::DB.connect $config[:db][:commits], $config[:db][:crunchbase]
n = GitAnalytics::DB::Commit.count
GitAnalytics::DB::Commit.find_each do |commit|
  ac = commit.author.domain.company
  cc = commit.committer.domain.company
  process commit, 'author-committer', ac, cc
  commit.signatures.find_each do |signature|
    sc = signature.person.domain.company
    process commit, 'author-signedoff', ac, sc
    process commit, 'committer-signedoff', cc, sc
  end
  
  n -= 1
  $l.info('%d left' % n) if n % 1000 == 0
end

