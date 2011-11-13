
module GitAnalytics
  module Schema

    def self.create_tables
      ActiveRecord::Schema.define do
        create_table   :commits do |t|
          t.string     :sha1,        :default => '', :limit => 40
          t.string     :origin,      :default => '', :limit => 32
          t.string     :project,     :default => '', :limit => 128
          t.string     :description, :default => '', :limit => 128
          t.text       :tag,         :default => ''
          t.text       :message,     :default => ''
          t.datetime   :author_date
          t.datetime   :committer_date
          t.references :author, :committer
          t.timestamps
        end
        create_table   :people do |t|
          t.string     :name,  :default => '', :limit => 128
          t.string     :email, :default => '', :limit => 128
          t.references :company
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
      end
    end
    
    def self.add_indexes
      ActiveRecord::Schema.define do
        add_index :commits, :sha1
        add_index :commits, :author_id
        add_index :commits, :committer_id
        add_index :people, :email
        add_index :people, :company_id
        add_index :modifications, :commit_id
        add_index :signatures, :person_id
        add_index :signatures, :commit_id
      end
    end
  end
end
