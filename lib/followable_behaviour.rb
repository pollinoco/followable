# frozen_string_literal: true

require_relative "followable_behaviour/version"

module FollowableBehaviour
  class Error < StandardError; end
  
  autoload :Follower,     'followable_behaviour/follower'
  autoload :Followable,   'followable_behaviour/followable'
  autoload :FollowerLib,  'followable_behaviour/follower_lib'
  autoload :FollowScopes, 'followable_behaviour/follow_scopes'

  require 'followable_behaviour/railtie' if defined?(Rails) && Rails::VERSION::MAJOR >= 6
  
end
