
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
        create_table   :emails do |t|
          t.string     :raw, :default => '', :limit => 256
          t.string     :name, :defailt => '', :limit => 128
          t.string     :username, :default => '', :limit => 32
          t.string     :subdomain, :default => '', :limit => 32
          t.string     :orgdomain, :default => '', :limit => 64
          t.references :company
        end
        create_table   :modifications do |t|
          t.references :commit
          t.references :metafile
          t.integer    :linechanges, :default => 0
        end
        create_table   :metafiles do |t|
          t.string     :path, :default => '', :limit => 64
        end
        create_table   :signatures do |t|
          t.string     :name, :default => '', :limit => 32
          t.references :email
          t.references :commit
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
        add_index :signatures, :email_id
        add_index :signatures, :commit_id
        add_index :modifications, :commit_id
        add_index :modifications, :metafile_id
        add_index :emails, :raw
        add_index :emails, :orgdomain
      end
    end
    
    def self.remove_indexes
      ActiveRecord::Schema.define do
        remove_index :commits, :sha1
        remove_index :commits, :author_id
        remove_index :commits, :committer_id
        remove_index :commits, :project_id
        remove_index :signatures, :email_id
        remove_index :signatures, :commit_id
        remove_index :modifications, :commit_id
        remove_index :modifications, :metafile_id
        remove_index :emails, :raw
        remove_index :emails, :orgdomain
      end
    end

    class Commit < ActiveRecord::Base
      has_many :signatures
      has_many :modifications
      has_many :metafiles, :through => :modifications
      belongs_to :author, :foreign_key => 'author_id',
                 :class_name => 'Email'
      belongs_to :committer, :foreign_key => 'committer_id',
                 :class_name => 'Email'
      belongs_to :project
    end

    class Email < ActiveRecord::Base
      belongs_to :company
      has_many :signatures, :dependent => :delete_all
    end

    class Modification < ActiveRecord::Base
      belongs_to :commit
      belongs_to :metafile
    end

    class Metafile < ActiveRecord::Base
      has_many :modifications
      has_many :commits, :through => :modifications
    end

    class Signature < ActiveRecord::Base
      belongs_to :email
      belongs_to :commit
    end

    class Server < ActiveRecord::Base
      has_many :projects
    end

    class Project < ActiveRecord::Base
      belongs_to :server
      has_many :commits
      has_many :metafiles, :through => :commits
    end

    def self.connect(commits)
      ActiveRecord::Base.establish_connection commits
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
        c.author         = create_email(log[:author])
        c.committer      = create_email(log[:committer])
        c.signatures     = create_signatures(log)
        c.modifications  = create_modifications(log)
      end
    end

    private

    def self.create_email(data)
      Email.find_or_create_by_raw(data[:raw_email])
    end

    def self.create_signatures(log)
      log[:signatures].map do |signature|
        email = create_email(signature)
        email.signatures.create(:name => signature[:name])
      end
    end

    def self.create_modifications(log)
      log[:modifications].map do |modification|
        metafile = Metafile.find_or_create_by_path(modification[:path])
        metafile.modifications.create(:linechanges => modification[:linechanges])
      end
    end
  end
end
