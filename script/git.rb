
module GitAnalytics
  module Git

    def self.count(gitdir, range='')
      git = "git --git-dir #{gitdir} log #{range} --oneline | wc -l"
      m = IO.popen(git).read.to_i
    end

    def self.log(gitdir, range='', extra={})
      git = "git --git-dir #{gitdir} log #{range} -z --decorate --stat --pretty=raw"
      IO.popen(git){|io| io.each("\0") do |line|
        data = parse(line, extra) rescue parse(line.encode(Encoding::UTF_8, Encoding::ISO8859_1), extra)
        yield(data)
      end}
      GitAnalytics::Email.save
    end

    private

    @signatures = "Signed-off-by|Reported-by|Reviewed-by|Tested-by|Acked-by|Cc"
    @re_signatures = /^    (#@signatures): (.* <(.+)>|.*)$/
    @re_modifications = /^ (.+) \|\s+(\d+) /
    @re_person = Hash.new{|hash, key| hash[key] = /^#{key} (.*) <(.*)> (.*) (.*)$/}
    @re_message = /^    (.*)$/
    @re_commit = /^commit (\S+) ?(.*)$/

    def self.parse(line, extra)
      line = line.strip

      sha1, tag = @re_commit.match(line).captures
      message = line.scan(@re_message).join("\n").strip

      {
        :sha1           => sha1,
        :tag            => tag,
        :message        => message,
        :author         => parse_person('author', line),
        :committer      => parse_person('committer', line),
        :signatures     => parse_signatures(line),
        :modifications  => parse_modifications(line)
      }.update(extra)
    end

    def self.create_date(secs, offset)
      Time.at(secs.to_i).getlocal(offset.insert(3, ':'))
    end

    def self.create_person(name, email)
      email = GitAnalytics::Email.fix(email || name)
      domain = GitAnalytics::Email.domain(email)
      {:name => name, :email => email, :domain => domain}
    end

    def self.parse_signatures(line)
      line.scan(@re_signatures).map do |key, name, email|
        {:name => key, :person => create_person(name, email)}
      end
    end

    def self.parse_modifications(line)
      line.scan(@re_modifications).map{|p, c| {:path => p.strip, :linechanges => c.to_i}}
    end

    def self.parse_person(header, line)
      name, email, secs, offset = @re_person[header].match(line).captures
      date = create_date(secs, offset)
      create_person(name, email).update(:date => date)
    end
  end
end
