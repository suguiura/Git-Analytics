
module GitAnalytics
  module DB
    $: << File.dirname(__FILE__)
    require 'config'

    def self.store(log)
      author = create_person(log[:author][:name], log[:author][:email])
      committer = create_person(log[:committer][:name], log[:committer][:email])
      commit = Commit.create do |c|
        c.origin         = log[:origin]
        c.project        = log[:name]
        c.description    = log[:description]
        c.sha1           = log[:sha1]
        c.tag            = log[:tag]
        c.message        = log[:message]
        c.author_date    = log[:author][:date]
        c.committer_date = log[:committer][:date]
        c.author         = author
        c.committer      = committer
        c.signatures     = create_signatures(log)
        c.modifications  = create_modifications(log)
      end
    end

    private

    def self.create_person(name, email)
      Person.find_or_create_by_email(fix_email(email), :name => name)
    end

    def self.create_signatures(log)
      log[:signatures].map do |signature|
        name, email = signature[:person][:name], signature[:person][:email]
        create_person(name, email).signatures.create(:name => signature[:name])
      end
    end

    def self.create_modifications(log)
      log[:modifications].map do |modification|
        Modification.create(modification)
      end
    end
  end
end
