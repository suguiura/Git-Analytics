#!/usr/bin/env ruby

# Copyright (C) 2011  Rafael S. Suguiura <rafael.suguiura@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

$: << File.join(File.dirname(__FILE__), '.')
require 'config'

each_server_config("Creating database for ") do |server, config|
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
    add_index :commits, :sha1
    add_index :commits, :author_id
    add_index :commits, :committer_id

    create_table   :people do |t|
      t.string     :name,  :default => '', :limit => 128
      t.string     :email, :default => '', :limit => 128
      t.references :company
    end
    add_index :people, :email
    add_index :people, :company_id
    
    create_table   :modifications do |t|
      t.string     :path, :default => '', :limit => 64
      t.integer    :linechanges, :default => 0
      t.references :commit
    end
    add_index :modifications, :commit_id
    
    create_table   :signatures do |t|
      t.string     :name, :default => '', :limit => 32
      t.references :person, :commit
    end
    add_index :signatures, :person_id
    add_index :signatures, :commit_id
  end
end

