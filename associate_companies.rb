#!/usr/bin/env ruby

require 'yaml'
require 'logger'
require 'active_record'

$l = Logger.new STDERR
$l.formatter = Logger::Formatter.new

$l.info 'Start'

$config = YAML.load_file 'config.yaml'
$dictionary = YAML.load_file 'company_domain.yaml'

ActiveRecord::Base.establish_connection $config[:db][:commits]

class Domain < ActiveRecord::Base
  belongs_to :company
end

class Company < ActiveRecord::Base
  establish_connection $config[:db][:crunchbase]
end

$first_company = Company.find(1)
choice = Hash.new do |h, domain|
  condition = {:orgdomain => domain.orgdomain}
  h[domain] = if $dictionary.key? domain.address
    Company.find_by_permalink $dictionary[domain.address]
  else
    if domain.orgdomain.empty? or (companies = Company.where(condition)).empty?
      $first_company
    else
      if companies.size == 1
        companies.first
      else
        puts 'email domain: %s' % domain.address
        (companies.unshift $first_company).each_with_index do |c, i|
          puts '%d - %s (%s)' % [i, c.permalink, c.homepage]
        end
        n = i = companies.size
        while not(0 <= i and i < companies.size)
          i = (print '> '; gets.strip.to_i)
        end
        companies[i]
        puts '----------'
      end
    end
  end
end

n = Domain.count
$l.info 'total: %d' % n
Domain.find_each do |domain|
  $l.info '%d' % n if (n -= 1) % 100 == 0
  domain.company = choice[domain]
  domain.save
end

$l.info 'Finish'

