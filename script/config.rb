
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

def each_server_config(prefix=nil, suffix='')
  selectors = ARGV.map do |arg|
    server, project = arg.split('.').map{|x| x.to_sym}
    next unless $config[:servers].key?(server)
    $l.info(prefix + server.to_s + suffix) unless prefix.nil?
    ActiveRecord::Base.establish_connection $config[:servers][server][:db]
    projects = {project => $projects[server][project.to_s]}
    projects = $projects[server] if project.nil?
    yield(server, $config[:servers][server], projects)
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

