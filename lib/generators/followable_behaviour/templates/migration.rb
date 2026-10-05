class FollowableBehaviourMigration < ActiveRecord::Migration[<%= ActiveRecord::Migration.current_version %>]
  def change
    create_table :follows do |t|
      t.references :followable, polymorphic: true, null: false, index: false
      t.references :follower, polymorphic: true, null: false, index: false
      t.boolean :blocked, default: false, null: false
      t.timestamps
    end

    add_index :follows,
              [:follower_type, :follower_id, :followable_type, :followable_id],
              unique: true,
              name: "index_follows_on_follower_and_followable"

    add_index :follows,
              [:followable_type, :followable_id, :follower_type, :follower_id],
              name: "index_follows_on_followable_and_follower"
  end
end
