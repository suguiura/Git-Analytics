
module GitAnalytics
  module DB

    def self.create_tables
      ActiveRecord::Schema.define do
        create_table   :commits do |t|
          t.string     :sha1, :default => '', :limit => 40
          t.text       :tag, :default => ''
          t.text       :message, :default => ''
          t.datetime   :author_date
          t.datetime   :committer_date
          t.references :author
          t.references :committer
          t.references :project
          t.timestamps
        end
        create_table   :people do |t|
          t.string     :name, :default => '', :limit => 128
          t.string     :email, :default => '', :limit => 128
          t.references :domain
        end
        create_table   :modifications do |t|
          t.string     :path, :default => '', :limit => 64
          t.integer    :linechanges, :default => 0
          t.references :commit
        end
        create_table   :signatures do |t|
          t.string     :name, :default => '', :limit => 32
          t.references :person, :commit
        end
        create_table   :domains do |t|
          t.string     :address, :default => '', :limit => 128
          t.string     :subdomain, :default => '', :limit => 32
          t.string     :orgdomain, :default => '', :limit => 64
          t.references :company
        end
        create_table   :servers do |t|
          t.string     :name, :null => false, :limit => 128
        end
        create_table   :projects do |t|
          t.string     :origin, :default => '', :limit => 32
          t.string     :name, :default => '', :limit => 128
          t.string     :description, :default => '', :limit => 128
          t.references :server
        end
      end
    end
    
    def self.add_indexes
      ActiveRecord::Schema.define do
        add_index :commits, :sha1
        add_index :commits, :author_id
        add_index :commits, :committer_id
        add_index :commits, :project_id
        add_index :people, :email
        add_index :people, :domain_id
        add_index :signatures, :person_id
        add_index :signatures, :commit_id
        add_index :modifications, :commit_id
        add_index :domains, :name
      end
    end
    
    def self.remove_indexes
      ActiveRecord::Schema.define do
        remove_index :commits, :sha1
        remove_index :commits, :author_id
        remove_index :commits, :committer_id
        remove_index :commits, :project_id
        remove_index :people, :email
        remove_index :people, :domain_id
        remove_index :signatures, :person_id
        remove_index :signatures, :commit_id
        remove_index :modifications, :commit_id
        remove_index :domains, :name
      end
    end

    class Commit < ActiveRecord::Base
      has_many :modifications
      has_many :signatures
      belongs_to :author, :foreign_key => 'author_id',
                 :class_name => 'Person'
      belongs_to :committer, :foreign_key => 'committer_id',
                 :class_name => 'Person'
      belongs_to :project
    end

    class Person < ActiveRecord::Base
      belongs_to :domain
      has_many :signatures, :dependent => :delete_all
    end

    class Author < Person
      has_many :commits, :foreign_key => 'author_id'
    end

    class Committer < Person
      has_many :commits, :foreign_key => 'committer_id'
    end

    class Modification < ActiveRecord::Base
      belongs_to :commit
    end

    class Signature < ActiveRecord::Base
      belongs_to :person
      belongs_to :commit
    end

    class Domain < ActiveRecord::Base
      belongs_to :company
      has_many :people
      has_many :authors
      has_many :committers
      has_many :author_commits, :through => :authors, :source => :commits
      has_many :committers_commits, :through => :committers, :source => :commits
    end

    class Server < ActiveRecord::Base
      has_many :projects
    end

    class Project < ActiveRecord::Base
      belongs_to :server
      has_many :commits
    end

    class Company < ActiveRecord::Base
      has_many :domains
      has_many :similarities
    end

    class Similarity < ActiveRecord::Base
    end

    def self.connect(commits, crunchbase)
      ActiveRecord::Base.establish_connection commits
      Company.establish_connection crunchbase
      Similarity.establish_connection crunchbase
    end

    def self.enable_log
      ActiveRecord::Base.logger = Logger.new STDERR
    end

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
        p.domain = Domain.find_or_create_by_address(data[:domain]) do |d|
          d.company = Company.find_by_orgdomain(data[:domain][:orgdomain])
        end
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
