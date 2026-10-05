# frozen_string_literal: true

require_relative "follower_lib"

module FollowableBehaviour
  module FollowScopes
    def self.extended(model)
      return if model.respond_to?(:for_follower)

      model.class_eval do
        scope :for_follower, lambda { |follower|
          where(
            follower_id: follower.id,
            follower_type: FollowableBehaviour::FollowerLib.parent_class_name(follower)
          )
        }

        scope :for_followable, lambda { |followable|
          where(
            followable_id: followable.id,
            followable_type: FollowableBehaviour::FollowerLib.parent_class_name(followable)
          )
        }

        scope :for_follower_type, ->(follower_type) { where(follower_type: follower_type) }
        scope :for_followable_type, ->(followable_type) { where(followable_type: followable_type) }

        # `>` estricto, igual que el alcance original. El tiempo se pasa como
        # objeto: `to_s(:db)` dejó de existir en Rails 7.1 y además perdía la zona.
        scope :recent, lambda { |from = nil|
          where(arel_table[:created_at].gt(from || 2.weeks.ago))
        }

        scope :descending, -> { order(arel_table[:created_at].desc) }
        scope :unblocked, -> { where(blocked: false) }
        scope :blocked, -> { where(blocked: true) }
      end
    end
  end
end
