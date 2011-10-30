
class Commit < ActiveRecord::Base
  has_many :modifications
  belongs_to :author, :class_name => 'Person', :foreign_key => 'author_id'
  belongs_to :committer, :class_name => 'Person', :foreign_key => 'committer_id'
  has_and_belongs_to_many :signatures
end

class Person < ActiveRecord::Base
  has_many :commits
  has_many :signatures
end

class Modification < ActiveRecord::Base
  belongs_to :commit
end

class Signature < ActiveRecord::Base
  belongs_to :person
end

