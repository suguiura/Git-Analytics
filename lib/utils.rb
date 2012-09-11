
$l = Logger.new STDERR
$l.formatter = Logger::Formatter.new
#$l.datetime_format = "%H:%M:%S"

$config = YAML::load_file 'config/general.yaml'
$projects = YAML.load_file($config[:list]) rescue {}

def each_server_config(prefix='', suffix='')
  ARGV.each do |arg| server, project = arg.split('.', 2)
    $l.info(prefix + server + suffix) unless prefix.empty?
    next if (config = $config[:servers][server = server.to_sym]).nil?
    projects = $projects[server].select{|k,v| project.nil? || project == k}
    yield(server, config, projects)
  end
end

def step_log(n, step, prefix='', suffix=' left')
  $l.info "%s%d%s" % [prefix, n, suffix] if (n % step) == 0
  n - 1
end

