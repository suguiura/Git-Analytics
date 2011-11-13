#!/usr/bin/env ruby

require 'uri'
require 'optparse'
require 'yaml'

$: << File.join(File.dirname(__FILE__), '.')
require 'config'

fix_email(nil)
emails = $emailfixmap

perlexpr = 'print $_ unless Mail::RFC822::Address::valid($_)'
check = "perl -I#{File.dirname(__FILE__)} -MAddress -ne '#{perlexpr}'"

each_server_config("Fixing emails for ") do |server, config|
  n = $projects[server].size
  $projects[server].each do |path, project| n -= 1
    puts "%5d - %s" % [n, path]
    dir, range = project[:dir], project[:range]
    git = "git --git-dir #{dir} log --pretty='%aE%x0A%cE' #{range}"
    cmd = "#{git} | sort | uniq | #{check}"
    IO.popen(cmd){|io|io.read}.split("\n").each do |bad_email|
      next unless emails[bad_email].nil?
      bad_email.strip!
      email = URI.unescape(bad_email)
      email.gsub! /DOT/, '.'
      email.gsub! /AT/, '@'
      email.downcase!
      email.gsub! /[^-._@a-z0-9]/, ' '
      email.squeeze! ' '
      email.gsub! /[ _.-]+at[-._ ]+/, '@'
      email.gsub! /[ _.-]+dot[-._ ]+/, '.'
      email.gsub! /^[ _.-]+|[-._ ]+$/, ''
      email.sub!(' ', '@') if email.count('@') == 0
      email.gsub! ' ', '.'
      email.squeeze! '.'
      email.sub! /(^no\.author\.@)|(@.*\.none$)/, ''
      emails[bad_email] = email
    end
  end
end

File.open($config[:emailfix], 'w').puts emails.to_yaml
$l.info 'Done.'

