# frozen_string_literal: true

require "logger"
require "active_record"
require "followable_behaviour"
require "minitest/autorun"

ActiveRecord::Base.logger = Logger.new(File::NULL)
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Base.include FollowableBehaviour::Follower
ActiveRecord::Base.include FollowableBehaviour::Followable

ActiveRecord::Schema.define do
  create_table :follows, force: true do |t|
    t.string :followable_type, null: false
    t.integer :followable_id, null: false
    t.string :follower_type, null: false
    t.integer :follower_id, null: false
    t.boolean :blocked, default: false, null: false
    t.string :seller_code
    t.timestamps
  end

  add_index :follows,
            %i[follower_type follower_id followable_type followable_id],
            unique: true,
            name: "index_follows_on_follower_and_followable"
  add_index :follows,
            %i[followable_type followable_id follower_type follower_id],
            name: "index_follows_on_followable_and_follower"

  create_table :users, force: true do |t|
    t.string :name
    t.string :type
  end

  create_table :stores, force: true do |t|
    t.string :name
  end

  create_table :books, force: true do |t|
    t.string :name
  end
end

class Follow < ActiveRecord::Base
  extend FollowableBehaviour::FollowScopes

  belongs_to :followable, polymorphic: true
  belongs_to :follower, polymorphic: true

  def block!
    update_columns(blocked: true, updated_at: Time.current)
  end
end

class User < ActiveRecord::Base
  follower_behaviour
  followable_behaviour
end

class Admin < User
end

class Store < ActiveRecord::Base
  followable_behaviour
end

class Book < ActiveRecord::Base
  followable_behaviour
end
