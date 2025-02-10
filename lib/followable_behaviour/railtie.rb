require 'rails'

module FollowableBehaviour
  class Railtie < Rails::Railtie

    initializer "acts_as_follower.active_record" do |app|
      ActiveSupport.on_load :active_record do
        include FollowableBehaviour::Follower
        include FollowableBehaviour::Followable
      end
    end

  end
end
