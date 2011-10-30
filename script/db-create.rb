#!/usr/bin/env ruby

$: << File.join(File.dirname(__FILE__), '.')
require 'config'

ActiveRecord::Schema.define do
  create_table   :commits, :force => true do |t|
    t.string     :origin,                :default => '', :limit => 32
    t.string     :project, :description, :default => '', :limit => 128
    t.text       :tag, :message,   :default => ''
    t.date       :author_date, :committer_date
    t.references :author, :committer
    t.timestamps
  end

  create_table   :people, :force => true do |t|
    t.string     :name, :email, :default => '', :limit => 128
  end
  create_table   :modifications, :force => true do |t|
    t.string     :path, :default => '', :limit => 64
    t.integer    :linechanges, :default => 0
    t.references :commit
  end
  create_table   :signatures, :force => true do |t|
    t.string     :name, :default => '', :limit => 32
    t.references :person
  end

  create_table   :commits_signatures, :force => true, :id => false do |t|
    t.references :commit, :signature
  end
end

