# frozen_string_literal: true

require "rails/railtie"

module FollowableBehaviour
  class Railtie < Rails::Railtie
    initializer "followable_behaviour.active_record" do
      ActiveSupport.on_load(:active_record) do
        include FollowableBehaviour::Follower
        include FollowableBehaviour::Followable
      end
    end
  end
end
