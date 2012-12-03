module GitAnalytics
  module Email

    def self.prepare(file)
      @fix_email.update(YAML.load_file(@file = file)) rescue nil
    end

    def self.save
      emails = @fix_email.delete_if{|k, v| k == v.to_s}
      File.open(@file, 'w').puts emails.to_yaml
    end

    def self.parse(raw_email)
      raw = @fix_email[raw_email].to_s || raw_email
      e = Mail::Address.new(raw.encode(Encoding::UTF_8, Encoding::ISO8859_1))
      d = Domainatrix.parse 'http://%s' % e.domain rescue return {
        :name => (e.name rescue ''),
        :address => (e.address rescue ''),
        :username => (e.local rescue ''),
        :host => (e.domain rescue ''),
        :subdomain => '',
        :domain => '',
        :public_suffix => '',
      }
      {
        :name => e.name,
        :address => e.address,
        :username => e.local,
        :host => e.domain,
        :subdomain => d.subdomain,
        :domain => d.domain,
        :public_suffix => d.public_suffix,
      }
    end
    
    private

    EmailVeracity::Config[:skip_lookup] = true
    @fix_email = Hash.new{|h, e| h[e] = do_fix(e)}

    def self.do_fix(email)
      e = EmailVeracity::Address.new(email)
      unless e.valid?
        email = URI.unescape(email)
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
        e = EmailVeracity::Address.new(email)
      end
      e
    end
  end
end
