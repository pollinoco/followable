# frozen_string_literal: true

require "rails/generators"
require "rails/generators/migration"

class FollowableBehaviourGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  source_root File.expand_path("templates", __dir__)

  def self.next_migration_number(dirname)
    if ActiveRecord::Base.timestamped_migrations
      Time.now.utc.strftime("%Y%m%d%H%M%S")
    else
      format("%.3d", current_migration_number(dirname) + 1)
    end
  end

  def create_migration_file
    migration_template "migration.rb", "db/migrate/followable_behaviour_migration.rb"
  end

  def create_model
    template "model.rb", "app/models/follow.rb"
  end
end
