#!/usr/bin/env ruby

require 'yaml'
require 'logger'
require 'active_record'

$l = Logger.new STDERR
$l.formatter = Logger::Formatter.new

$l.info 'Start'

$config = YAML::load_file 'config.yaml'

ActiveRecord::Base.establish_connection $config[:db][:commits]
=begin
ActiveRecord::Schema.define do
# http://api.rubyonrails.org/classes/ActiveRecord/Migration.html
  add_column :modifications, :metafile_id, :integer
  add_index :modifications, :metafile_id
  create_table   :metafiles do |t|
    t.string     :path, :default => '', :limit => 64
  end
  add_index :metafiles, :path
#  remove_column :modifications, :path
end
=end

class Metafile < ActiveRecord::Base
  has_many :modifications
end

class Modification < ActiveRecord::Base
  belongs_to :metafile
end

n = Modification.count
$l.info "total: %d" % n
Modification.find_each do |modification|
  modification.metafile = Metafile.find_or_create_by_path modification.path
  modification.save
  $l.info "%d left" % [n] if (n -= 1) % 10000 == 0
end

$l.info 'Done'

