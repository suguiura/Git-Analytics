#!/usr/bin/env ruby

require 'yaml'
require 'active_record'

load 'lib/db.rb'

$config = YAML.load_file 'config.yaml'

GitAnalytics::DB.connect $config[:db][:commits], $config[:db][:crunchbase]

GitAnalytics::DB::Domain.find_each do |domain|
  x = domain.orgdomain
  p x if GitAnalytics::DB::Company.find_all_by_orgdomain(x).size > 1
end

