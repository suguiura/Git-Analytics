require 'yaml'

module Git

  def self.count(gitdir, range='')
    git = "git --git-dir #{gitdir} log #{range} --oneline | wc -l"
    m = IO.popen(git).read.to_i
  end

  def self.log(gitdir, range='')
    git = "git --git-dir #{gitdir} log #{range} -z --decorate --stat --pretty=raw"
    IO.popen(git){|io| io.each("\0"){|line| yield(parse(line))}}
  end

  private

  @signatures = "Signed-off-by|Reported-by|Reviewed-by|Tested-by|Acked-by|Cc"
  @re_signatures = /^    (#@signatures): (.* <(.+)>|.*)$/
  @re_changes = /^ (.+) \|\s+(\d+) /
  @re_person = Hash.new{|hash, key| hash[key] = /^#{key} (.*) <(.*)> (.*) (.*)$/}
  @re_message = /^    (.*)$/
  @re_commit = /^commit (\S+) ?(.*)$/

  def self.create_person(name, email)
    {:name => name, :email => email}
  end

  def self.create_date(secs, offset)
    Time.at(secs.to_i).getlocal(offset.insert(3, ':'))
  end

  def self.parse_signatures(line)
    line.scan(@re_signatures).map do |key, name, email|
      {:signature => key, :person => create_person(name, email)}
    end
  end

  def self.parse_changes(line)
    line.scan(@re_changes).map{|p, c| {:path => p.strip, :linechanges => c}}
  end

  def self.parse_person(header, line)
    name, email, secs, offset = @re_person[header].match(line).captures
    {:date => create_date(secs, offset)}.update(create_person(name, email))
  end

  def self.parse(line)
    line = line.encode(Encoding::UTF_8, Encoding::ISO8859_1).strip
    
    sha1, tag = @re_commit.match(line).captures
    message = line.scan(@re_message).join("\n").strip

    {
      :sha1           => sha1,
      :tag            => tag,
      :message        => message,
      :author         => parse_person('author', line),
      :committer      => parse_person('committer', line),
      :signatures     => parse_signatures(line),
      :changes        => parse_changes(line)
    }
  end
end

