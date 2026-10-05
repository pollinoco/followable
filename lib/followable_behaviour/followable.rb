# frozen_string_literal: true

module FollowableBehaviour
  module Followable
    FOLLOWERS_COUNT = /\Acount_(.+)_followers\z/
    FOLLOWERS_LIST = /\A(.+)_followers\z/

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def followable_behaviour
        has_many :followings, as: :followable, dependent: :destroy, class_name: "Follow"
        include FollowableBehaviour::Followable::InstanceMethods
        include FollowableBehaviour::FollowerLib
      end
      alias_method :acts_as_followable, :followable_behaviour
    end

    module InstanceMethods
      def followers_count
        followings.unblocked.count
      end

      def followers_by_type(follower_type, *args, **kwargs)
        klass = resolve_class(follower_type)
        relation = klass.joins(:follows).where(
          follows: {
            blocked: false,
            followable_id: id,
            followable_type: parent_class_name(self),
            follower_type: klass.base_class.name
          }
        )
        apply_options_to_scope(relation, merge_options(args, kwargs))
      end

      def followers_by_type_count(follower_type)
        klass = resolve_class(follower_type)
        scope = followings.unblocked.where(follower_type: klass.base_class.name)
        scope = scope.where(follower_id: klass.select(:id)) if klass != klass.base_class
        scope.count
      end

      def method_missing(method_name, *args, **kwargs, &block)
        kind, fragment = followable_dynamic_call(method_name)
        case kind
        when :count
          followers_by_type_count(fragment.singularize.classify)
        when :list
          followers_by_type(fragment.singularize.classify, *args, **kwargs)
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        followable_dynamic_call(method_name).present? || super
      end

      def blocked_followers_count
        followings.blocked.count
      end

      def followers_scoped
        followings.includes(:follower)
      end

      def followers(*args, **kwargs)
        scope = apply_options_to_scope(followers_scoped.unblocked, merge_options(args, kwargs))
        scope.filter_map(&:follower)
      end

      def blocks(*args, **kwargs)
        scope = apply_options_to_scope(followers_scoped.blocked, merge_options(args, kwargs))
        scope.filter_map(&:follower)
      end

      def followed_by?(follower)
        followings.unblocked.for_follower(follower).exists?
      end

      def block(follower)
        return if follower == self

        follow = get_follow_for(follower)
        if follow
          follow.block!
        else
          followings.create!(follower: follower, blocked: true)
        end
      end

      def unblock(follower)
        deleted = followings.for_follower(follower).delete_all
        deleted.positive? ? deleted : nil
      end

      def get_follow_for(follower)
        followings.for_follower(follower).order(id: :desc).take
      end

      private

      def followable_dynamic_call(method_name)
        name = -method_name.to_s
        if (match = FOLLOWERS_COUNT.match(name))
          [:count, match[1]]
        elsif (match = FOLLOWERS_LIST.match(name))
          [:list, match[1]]
        end
      end
    end
  end
end
