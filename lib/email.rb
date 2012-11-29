module GitAnalytics
  module Email

    def self.prepare(file)
      @fix_email.update(YAML.load_file(@file = file)) rescue nil
    end

    def self.save
      emails = @fix_email.delete_if{|k, v| k == v.to_s}
      File.open(@file, 'w').puts emails.to_yaml
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
