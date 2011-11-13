
# Copyright (C) 2011  Rafael S. Suguiura <rafael.suguiura@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'yaml'
require 'logger'
require 'rubygems'
require 'active_record'
require 'models'

$l = Logger.new STDERR
$l.formatter = Logger::Formatter.new
#$l.datetime_format = "%H:%M:%S"

$config = YAML::load_file 'config.yaml'
$projects = begin; YAML.load_file($config[:global][:list][:file]); rescue; {}; end

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

$fix_email = YAML.load_file($config[:global][:emailfix][:file]) rescue {}
def fix_email(email)
  $fix_email[email] || email
end

def step_log(n, step, prefix='', suffix=' left')
  $l.info "%s%d%s" % [prefix, n, suffix] if (n % step) == 0
  n - 1
end

