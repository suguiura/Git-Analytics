
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
path = $config[:global][:list][:file]
$projects = begin; YAML.load_file(path); rescue; {}; end

#ActiveRecord::Base.logger = Logger.new STDERR

Company.establish_connection $config[:crunchbase][:db]

def each_server_config
  servers = ARGV.map{|x| x.to_sym} & $config[:servers].keys
  servers = $config[:servers].keys if servers.empty?
  servers.each{|server| yield(server, $config[:servers][server])}
end

