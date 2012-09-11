#!/usr/bin/env ruby

require 'logger'
require 'active_record'

load 'lib/db.rb'

def process_data(commit, type, company, other_company)
  a, b = company, other_company
  a_permalink = a.permalink rescue return
  b_permalink = b.permalink rescue return
  return if a.permalink.nil? or b.permalink.nil?
  competition = a.competitors.include? b
  counter = a.similarities.find_by_other_company_id(b.id).counter rescue 0
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

def process
  puts %w(server origin project description org1 org2 author_date commit_date
          filechanges relationship competition tag_similarity).join("\t")
  n = GitAnalytics::DB::Commit.count
  GitAnalytics::DB::Commit.find_each do |commit|
    ac = commit.author.company
    cc = commit.committer.company
    process_data commit, 'author-committer', ac, cc
    commit.signatures.find_each do |signature|
      sc = signature.email.company
      process_data commit, 'author-signedoff', ac, sc
      process_data commit, 'committer-signedoff', cc, sc
    end
    $l.info('%d left' % n) if (n -= 1) % 1000 == 0
  end
end

def prepare
  require 'yaml'
  config = YAML::load_file 'config/general.yaml'
  GitAnalytics::DB.connect config[:db][:commits]
  GitAnalytics::DB::Company.establish_connection config[:db][:crunchbase]
  GitAnalytics::DB::Similarity.establish_connection config[:db][:crunchbase]
  GitAnalytics::DB::Tag.establish_connection config[:db][:crunchbase]
end

$l = Logger.new STDERR
$l.formatter = Logger::Formatter.new

$l.info 'Start'
prepare
process
$l.info 'Finish'

