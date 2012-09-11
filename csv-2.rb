#!/usr/bin/env ruby

require 'logger'
require 'active_record'

load 'lib/db.rb'

def relate_companies(company, other_company)
  a, b = company, other_company
  a_permalink = a.permalink || raise
  b_permalink = b.permalink || raise
  competition = a.competitors.include? b
  counter = a.similarities.find_by_other_company_id(b.id).counter rescue 0
  similarity = counter.to_f / a.tags.size rescue 0.0
  [a_permalink, b_permalink, competition, similarity]
end

def process_companies(project, companies)
  companies.each do |path, array|
    array.uniq.permutation(2).each do |company, other_company|
      puts [
        path,
        project.server.name,
        project.origin,
        project.name,
        relate_companies(company, other_company)
      ].join("\t")
    end
  end
end

def process
  puts %w(file server origin project org1 org2 competition tag_similarity).join("\t")
  $l.info 'projects: %d' % (n = GitAnalytics::DB::Project.count)
  GitAnalytics::DB::Project.find_each do |project|
    $l.info '%d: %s' % [n -= 1, project.name]
    companies = Hash.new{|h, v| h[v] = []}
    project.commits.find_each do |commit|
      company = commit.author.company
      commit.metafiles.find_each do |metafile|
        companies[metafile.path] << company
      end unless company.nil? or company.permalink.nil?
    end
    $l.info 'printing'
    process_companies project, companies
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

