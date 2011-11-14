
class Commit < ActiveRecord::Base
  has_many :modifications
  has_many :signatures
  belongs_to :author, :class_name => 'Person', :foreign_key => 'author_id'
  belongs_to :committer, :class_name => 'Person', :foreign_key => 'committer_id'
end

class Person < ActiveRecord::Base
  has_many :signatures
  belongs_to :company
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

class Company < ActiveRecord::Base
  has_many :authors
  has_many :committers
  has_many :author_commits, :through => :authors, :source => :commits
  has_many :committers_commits, :through => :committers, :source => :commits
end

