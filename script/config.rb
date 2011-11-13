
require 'yaml'
require 'logger'
require 'rubygems'
require 'active_record'
require 'models'

$l = Logger.new STDERR
$l.formatter = Logger::Formatter.new
#$l.datetime_format = "%H:%M:%S"

$config = YAML::load_file 'config.yaml'
$projects = YAML.load_file($config[:list]) rescue {}

#ActiveRecord::Base.logger = Logger.new STDERR

Company.establish_connection $config[:crunchbase][:db]

def each_server_config(info_prefix=nil, info_suffix='')
  servers = ARGV.map{|x| x.to_sym} & $config[:servers].keys
  servers = $config[:servers].keys if servers.empty?
  servers.each do |server|
    $l.info(info_prefix + server.to_s + info_suffix) unless info_prefix.nil?
    ActiveRecord::Base.establish_connection $config[:servers][server][:db]
    yield(server, $config[:servers][server])
  end
end

$fix_email = YAML.load_file($config[:emailfix]) rescue {}
def fix_email(email)
  $fix_email[email] || email
end

def step_log(n, step, prefix='', suffix=' left')
  $l.info "%s%d%s" % [prefix, n, suffix] if (n % step) == 0
  n - 1
end

