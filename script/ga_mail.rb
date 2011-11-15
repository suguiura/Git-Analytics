module GitAnalytics
  module Mail
    def self.fix(email)
      $fix_email[email] || email
    end

    def self.domain(email)
      $domains[email]
    end

    def self.save
      emails = $fix_email.delete_if{|k, v| k == v}
      File.open($config[:emailfix], 'w').puts emails.to_yaml
    end
    
    private

    $: << File.dirname(__FILE__)
    require 'config'
    require 'yaml'
    require 'email_veracity'

    EmailVeracity::Config[:skip_lookup] = true
    $emails = Hash.new do |hash, email|
      hash[email] = EmailVeracity::Address.new(email)
    end
    $domains = Hash.new do |hash, email|
      hash[email] = $emails[email].domain
    end
    $fix_email = Hash.new do |hash, email|
      hash[email] = if $emails[email].valid?
        email
      else
        email, old_email = URI.unescape(email), email
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
        email
      end
    end
    $fix_email.update(YAML.load_file($config[:emailfix])) rescue nil
  end
end
