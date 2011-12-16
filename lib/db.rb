
module GitAnalytics
  module DB

    def self.store_project(data)
      @project = Project.find_or_create_by_name(data[:project]) do |p|
        p.server      = Server.find_or_create_by_name(data[:server])
        p.origin      = data[:origin]
        p.description = data[:description]
      end
    end

    def self.store(log)
      Commit.create do |c|
        c.project        = @project
        c.sha1           = log[:sha1]
        c.tag            = log[:tag]
        c.message        = log[:message]
        c.author_date    = log[:author][:date]
        c.committer_date = log[:committer][:date]
        c.author         = create_person(log[:author])
        c.committer      = create_person(log[:committer])
        c.signatures     = create_signatures(log)
        c.modifications  = create_modifications(log)
      end
    end

    private

    def self.create_person(data)
      Person.find_or_create_by_email(data[:email]) do |p|
        p.name   = data[:name]
        p.domain = Domain.find_or_create_by_name(data[:domain])
      end
    end

    def self.create_signatures(log)
      log[:signatures].map do |signature|
        person = create_person(signature[:person])
        person.signatures.create(:name => signature[:name])
      end
    end

    def self.create_modifications(log)
      log[:modifications].map do |modification|
        Modification.create(modification)
      end
    end
  end
end
