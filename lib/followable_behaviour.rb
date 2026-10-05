# frozen_string_literal: true

require_relative "followable_behaviour/version"
require_relative "followable_behaviour/follower_lib"
require_relative "followable_behaviour/follow_scopes"
require_relative "followable_behaviour/follower"
require_relative "followable_behaviour/followable"

module FollowableBehaviour
  class Error < StandardError; end
end

require_relative "followable_behaviour/railtie" if defined?(Rails) && Rails.gem_version >= Gem::Version.new("6.0")
