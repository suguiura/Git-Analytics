
module GitAnalytics
  module DB
    $: << File.dirname(__FILE__)
    require 'config'

    def self.store(log)
      a, c = log[:author], log[:committer]
      author    = create_person(a[:name], a[:email], a[:domain])
      committer = create_person(c[:name], c[:email], c[:domain])
      server = Server.find_or_create_by_name(log[:server])
      commit = Commit.create do |c|
        c.server         = server
        c.origin         = log[:origin]
        c.project        = log[:project]
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

    def self.create_person(name, email, domain)
      domain = Domain.find_or_create_by_domain(domain)
      Person.find_or_create_by_email(email, :name => name, :domain => domain)
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
