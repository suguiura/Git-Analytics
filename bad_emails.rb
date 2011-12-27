#!/usr/bin/env ruby

require 'email_veracity'
require 'active_record'

EmailVeracity::Config[:skip_lookup] = true

config = {:adapter => 'sqlite3', :database => '/media/sd8a/commits.sqlite3'}
ActiveRecord::Base.establish_connection config
class Person < ActiveRecord::Base
end

Person.find_each do |person|
  e = EmailVeracity::Address.new person.email
  p person unless e.valid?
end

