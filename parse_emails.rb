#!/usr/bin/env ruby

require 'yaml'
require 'mail'
require 'iconv'
require 'domainatrix'
require 'active_record'

#EmailVeracity::Config[:skip_lookup] = true

$config = YAML.load_file 'config.yaml'
$fix = YAML.load_file 'rawfix.yaml'
$permalink = YAML.load_file 'company_domain.yaml'

ActiveRecord::Base.establish_connection $config[:db][:commits]

class Email < ActiveRecord::Base
  belongs_to :company
end

class Company < ActiveRecord::Base
  establish_connection $config[:db][:crunchbase]
end

n = Email.count
Email.find_each do |email|
  puts n if (n -= 1) % 1000 == 0
  raw = Iconv.iconv('ascii//translit', 'utf-8', email.raw).first
  raw = $fix[raw] || raw
  next if raw.empty?
  e = Mail::Address.new(raw)
  email.name = e.name
  email.username = e.local
  d = Domainatrix.parse 'http://%s' % e.domain rescue next
  email.subdomain = d.subdomain
  email.orgdomain = [d.domain, d.public_suffix].join('.')
  email.company = unless $permalink[email.orgdomain].nil?
    Company.find_by_permalink $permalink[email.orgdomain]
  else
    Company.find_by_orgdomain email.orgdomain
  end
  email.save
end
