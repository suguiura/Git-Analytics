#!/usr/bin/env ruby

require 'yaml'
require 'logger'
require 'active_record'

$l = Logger.new STDERR
$l.formatter = Logger::Formatter.new

$l.info 'Start'

$config = YAML::load_file 'config.yaml'

ActiveRecord::Base.establish_connection $config[:db][:commits]
ActiveRecord::Schema.define do
# http://api.rubyonrails.org/classes/ActiveRecord/Migration.html
  rename_table :domains, :emails
  rename_column :emails, :address, :raw
  rename_column :people, :domain_id, :email_id
  add_column :emails, :user, :default => '', :limit => 32
  add_index :emails, :raw
  add_index :emails, :orgdomain
  add_index :people, :email_id
  remove_index :people, :domain_id
  remove_index :people, :email
  remove_index :emails, :name
end

$l.info 'Done'

