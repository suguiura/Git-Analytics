module GitAnalytics
  module Email

    def self.prepare(file)
      @fix_email.update(YAML.load_file(@file = file)) rescue nil
    end

    def self.save
      emails = @fix_email.delete_if{|k, v| k == v}
      File.open(@file, 'w').puts emails.to_yaml
    end

    def self.parse(raw_email)
      email = @fix_email[raw_email].empty? ? raw_email : @fix_email[raw_email]
      email.encode!(Encoding::UTF_8, Encoding::ISO8859_1)
      begin
        e = Mail::Address.new(email)
        d = Domainatrix.parse 'http://%s' % e.domain
        {
          :name => e.name,
          :address => e.address,
          :username => e.local,
          :host => e.domain,
          :subdomain => d.subdomain,
          :domain => d.domain,
          :public_suffix => d.public_suffix,
        }
      rescue
        unless @bad_emails.include? raw_email
          @bad_emails << raw_email
          $l.error "Bad email: %s" % raw_email
        end
        Hash.new('')
      end
    end
    
    private

    EmailVeracity::Config[:skip_lookup] = true
    @fix_email = Hash.new{|h, e| h[e] = do_fix(e)}
    @bad_emails = []

    def self.do_fix(email)
      e = EmailVeracity::Address.new(email)
      e.valid? ? e.to_s : ''
    end
  end
end
