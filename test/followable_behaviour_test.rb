# frozen_string_literal: true

require_relative "test_helper"

class FollowableBehaviourTest < Minitest::Test
  def setup
    Follow.delete_all
    User.delete_all
    Store.delete_all
    Book.delete_all
  end

  def test_follow_is_idempotent_and_returns_the_same_row
    user = User.create!(name: "Ana")
    store = Store.create!(name: "Tienda")

    first = user.follow(store)
    second = user.follow(store)

    assert_equal first.id, second.id
    assert_equal 1, Follow.count
    assert user.following?(store)
    assert store.followed_by?(user)
  end

  def test_follow_does_not_write_when_nothing_changed
    user = User.create!(name: "Ana")
    store = Store.create!(name: "Tienda")
    user.follow(store, seller_code: "N1")

    statements = sql_statements { user.follow(store, seller_code: "N1") }

    assert statements.none? { |statement| statement.match?(/\AUPDATE/i) }
    assert statements.none? { |statement| statement.match?(/\AINSERT/i) }
  end

  def test_follow_saves_extra_attributes_on_the_existing_row
    user = User.create!(name: "Ana")
    store = Store.create!(name: "Tienda")
    created = user.follow(store)
    updated = user.follow(store, seller_code: "N1")

    assert_equal created.id, updated.id
    assert_equal "N1", updated.reload.seller_code
    assert_equal 1, Follow.count
  end

  def test_follow_ignores_self_and_unpersisted_records
    user = User.create!(name: "Ana")

    assert_nil user.follow(user)
    assert_raises(ArgumentError) { user.follow(Store.new(name: "Nueva")) }
    assert_equal 0, Follow.count
  end

  def test_follow_stores_the_sti_base_class
    admin = Admin.create!(name: "Ada")
    store = Store.create!(name: "Tienda")

    admin.follow(store)

    assert_equal "User", Follow.last.follower_type
    assert_equal "Store", Follow.last.followable_type
    assert admin.following?(store)
    assert store.followed_by?(admin)
  end

  def test_stop_following_is_truthy_only_when_a_row_was_destroyed
    user = User.create!(name: "Ana")
    store = Store.create!(name: "Tienda")
    user.follow(store)

    assert user.stop_following(store)
    assert_nil user.stop_following(store)
    assert_equal 0, Follow.count
  end

  def test_stop_following_removes_every_active_duplicate_and_keeps_blocked_rows
    drop_unique_index
    user = User.create!(name: "Ana")
    store = Store.create!(name: "Tienda")
    Follow.create!(followable: store, follower: user, blocked: false)
    Follow.create!(followable: store, follower: user, blocked: false)
    Follow.create!(followable: store, follower: user, blocked: true)

    assert user.stop_following(store)

    remaining = Follow.where(follower: user, followable: store)
    assert_equal [true], remaining.pluck(:blocked)
  ensure
    Follow.delete_all
    restore_unique_index
  end

  def test_following_and_followed_by_do_not_count_rows
    user = User.create!(name: "Ana")
    store = Store.create!(name: "Tienda")
    user.follow(store)

    following_sql = sql_statements { user.following?(store) }
    followed_sql = sql_statements { store.followed_by?(user) }

    assert following_sql.any? { |statement| statement.match?(/limit|exists/i) }
    assert followed_sql.any? { |statement| statement.match?(/limit|exists/i) }
    assert following_sql.none? { |statement| statement.match?(/count/i) }
    assert followed_sql.none? { |statement| statement.match?(/count/i) }
  end

  def test_block_loads_the_follow_once
    user = User.create!(name: "Ana")
    store = Store.create!(name: "Tienda")
    user.follow(store)

    statements = sql_statements { store.block(user) }
    selects = statements.grep(/\ASELECT/i)
    updates = statements.grep(/\AUPDATE/i)

    assert_equal 1, selects.size
    assert_equal 1, updates.size
    refute user.following?(store)
    refute store.followed_by?(user)
    assert_includes store.blocks, user
    refute_includes store.followers, user
  end

  def test_block_without_a_follow_creates_one_blocked_row
    user = User.create!(name: "Ana")
    store = Store.create!(name: "Tienda")

    store.block(user)

    assert_equal 1, Follow.count
    assert Follow.last.blocked
    assert_nil store.block(store)
  end

  def test_unblock_removes_the_row
    user = User.create!(name: "Ana")
    store = Store.create!(name: "Tienda")
    store.block(user)

    assert store.unblock(user)
    assert_nil store.unblock(user)
    assert_equal 0, Follow.count
  end

  def test_scopes_chain_and_recent_accepts_no_argument
    user = User.create!(name: "Ana")
    store = Store.create!(name: "Tienda")
    recent = user.follow(store)
    old = user.follow(Book.create!(name: "Libro"))
    old.update_columns(created_at: 3.weeks.ago, updated_at: 3.weeks.ago)

    found = Follow.unblocked.for_follower(user).recent.descending

    assert_equal [recent.id, old.id].sort, Follow.for_follower(user).pluck(:id).sort
    assert_equal [recent.id], found.pluck(:id)
    assert_equal [recent.id], Follow.recent(12.hours.ago).pluck(:id)
  end

  def test_keyword_arguments_and_dynamic_names
    user = User.create!(name: "Ana")
    first_store = Store.create!(name: "Uno")
    Store.create!(name: "Dos").tap { |store| user.follow(store) }
    user.follow(first_store)

    assert_equal 1, user.following_by_type("Store", limit: 1).size
    assert_equal 1, user.following_stores(limit: 1).size
    assert_equal 2, user.following_stores_count
    assert_equal 1, first_store.followers_by_type_count("User")
    assert_equal 2, user.follow_count
    assert user.respond_to?(:following_stores)
    assert user.respond_to?(:follow)
    refute user.respond_to?(:missing_method)
    assert first_store.respond_to?(:user_followers)
    refute first_store.respond_to?(:missing_method)
  end

  def test_sti_follower_counts_do_not_require_a_join_for_the_base_class
    admin = Admin.create!(name: "Ada")
    user = User.create!(name: "Ana")
    store = Store.create!(name: "Tienda")
    admin.follow(store)
    user.follow(store)

    assert_equal 2, store.followers_by_type_count("User")
    assert_equal 1, store.followers_by_type_count("Admin")
    assert_equal [admin], store.followers_by_type(Admin).to_a
    assert_equal 2, store.user_followers.size
    assert_equal 1, store.count_admin_followers
  end

  def test_collections_skip_missing_targets
    user = User.create!(name: "Ana")
    store = Store.create!(name: "Tienda")
    book = Book.create!(name: "Libro")
    user.follow(store)
    user.follow(book)
    store.delete

    assert_equal [book], user.all_following
    assert_equal [user], book.followers
  end

  def test_get_follow_returns_the_newest_unblocked_row
    drop_unique_index
    user = User.create!(name: "Ana")
    store = Store.create!(name: "Tienda")
    Follow.create!(followable: store, follower: user, blocked: false, seller_code: "viejo")
    newest = Follow.create!(followable: store, follower: user, blocked: false, seller_code: "nuevo")

    assert_equal newest.id, user.get_follow(store).id
    assert_equal "nuevo", user.follow(store).seller_code
  ensure
    Follow.delete_all
    restore_unique_index
  end

  def test_migration_template_creates_the_composite_indexes
    root = File.expand_path("..", __dir__)
    migration = File.read(File.join(root, "lib/generators/followable_behaviour/templates/migration.rb"))

    assert_includes migration, "unique: true"
    assert_includes migration, "index_follows_on_follower_and_followable"
    assert_includes migration, "index_follows_on_followable_and_follower"
    refute_match(/force:\s*true/, migration)
    refute_includes migration, "ActsAsFollowerMigration"
  end

  private

  def sql_statements
    statements = []
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |event|
      payload = event.payload
      statements << payload[:sql] unless payload[:name] == "SCHEMA"
    end
    yield
    statements
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end

  def drop_unique_index
    connection = ActiveRecord::Base.connection
    return unless connection.index_exists?(:follows, name: "index_follows_on_follower_and_followable")

    connection.remove_index :follows, name: "index_follows_on_follower_and_followable"
  end

  def restore_unique_index
    connection = ActiveRecord::Base.connection
    return if connection.index_exists?(:follows, name: "index_follows_on_follower_and_followable")

    connection.add_index :follows,
                          %i[follower_type follower_id followable_type followable_id],
                          unique: true,
                          name: "index_follows_on_follower_and_followable"
  end
end
