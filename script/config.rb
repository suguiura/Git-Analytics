
require 'yaml'
require 'logger'
require 'rubygems'
require 'active_record'
require 'models'

$l = Logger.new STDOUT
$l.formatter = Logger::Formatter.new
#$l.datetime_format = "%H:%M:%S"

$config = YAML::load_file 'config.yaml'

ActiveRecord::Base.establish_connection $config[:db][$config[:db][:current]]
#ActiveRecord::Base.logger = Logger.new STDERR

