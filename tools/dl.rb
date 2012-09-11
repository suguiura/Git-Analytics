#!/usr/bin/env ruby

require 'logger'
require 'yaml'

load 'lib/utils.rb'

each_server_config("Downloading projects for ") do |server, config, projects|
  n = projects.size
  projects.each do |path, project|
    n = step_log(n, 1, '', " - " + path)
    name, dir, url = project[:name], project[:dir], project[:git]
    case
    when project[:fork]
      system "git --git-dir=#{dir} remote add #{name} #{url}"
    when !File.exists?(dir)
      system "mkdir -p #{dir}; git clone --mirror #{url} #{dir}"
    end
    # --prune removes project forks, should be avoided
    system "git --git-dir=#{dir} remote update"
  end
end

