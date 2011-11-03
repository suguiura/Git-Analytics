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
  ActiveRecord::Base.establish_connection config[:db]
  ActiveRecord::Schema.define do
    create_table   :commits do |t|
      t.string     :sha1,                  :default => '', :limit => 40
      t.string     :origin,                :default => '', :limit => 32
      t.string     :project, :description, :default => '', :limit => 128
      t.text       :tag, :message,   :default => ''
      t.datetime   :author_date, :committer_date
      t.references :author, :committer
      t.timestamps
      t.index      :author_id
      t.index      :committer_id
    end

    create_table   :people do |t|
      t.string     :name, :email, :default => '', :limit => 128
      t.references :company
      t.index      :company_id
    end
    create_table   :modifications do |t|
      t.string     :path, :default => '', :limit => 64
      t.integer    :linechanges, :default => 0
      t.references :commit
      t.index      :commit_id
    end
    create_table   :signatures do |t|
      t.string     :name, :default => '', :limit => 32
      t.references :person
      t.index      :person_id
    end

    create_table   :commits_signatures, :id => false do |t|
      t.references :commit, :signature
      t.index      :commit_id
      t.index      :signature_id
    end
  end
end

