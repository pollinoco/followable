class Follow < ApplicationRecord
  extend FollowableBehaviour::FollowScopes

  belongs_to :followable, polymorphic: true
  belongs_to :follower, polymorphic: true

  def block!
    update_columns(blocked: true, updated_at: Time.current)
  end
end
