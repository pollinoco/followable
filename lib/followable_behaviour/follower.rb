# frozen_string_literal: true

module FollowableBehaviour
  module Follower
    FOLLOWING_COUNT = /\Afollowing_(.+)_count\z/
    FOLLOWING_LIST = /\Afollowing_(.+)\z/

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def follower_behaviour
        has_many :follows, as: :follower, dependent: :destroy
        include FollowableBehaviour::Follower::InstanceMethods
        include FollowableBehaviour::FollowerLib
      end
      alias_method :acts_as_follower, :follower_behaviour
    end

    module InstanceMethods
      def following?(followable)
        follows.unblocked.for_followable(followable).exists?
      end

      def follow_count
        follows.unblocked.count
      end

      # Crea el follow si no existe y devuelve el registro (el más reciente si
      # hubiera duplicados). Con un índice único, dos altas concurrentes no
      # dejan dos filas: la que pierde el INSERT relee la ganadora.
      # Atributos extra se asignan en la misma escritura, sin un find posterior.
      def follow(followable, attributes = {}, **kwargs)
        return if self == followable || followable.blank?

        attributes = sanitize_follow_attributes((attributes || {}).merge(kwargs))
        lookup = {
          followable_id: followable.id,
          followable_type: parent_class_name(followable)
        }
        raise ArgumentError, "followable must be persisted" if lookup[:followable_id].blank?

        record = follows.where(lookup).order(id: :desc).take
        return apply_follow_attributes(record, attributes) if record

        follows.create!(lookup.merge(attributes))
      rescue ActiveRecord::RecordNotUnique
        apply_follow_attributes(follows.where(lookup).order(id: :desc).take!, attributes)
      end

      # Destruye todos los follows activos de ese par. Devuelve los registros
      # destruidos, o nil si no había ninguno (`if record.stop_following(other)`).
      def stop_following(followable)
        destroyed = follows.unblocked.for_followable(followable).select(&:destroy)
        destroyed.presence
      end

      def follows_scoped
        follows.unblocked.includes(:followable)
      end

      def follows_by_type(followable_type, *args, **kwargs)
        apply_options_to_scope(follows_scoped.for_followable_type(followable_type), merge_options(args, kwargs))
      end

      def all_follows(*args, **kwargs)
        apply_options_to_scope(follows_scoped, merge_options(args, kwargs))
      end

      def all_following(*args, **kwargs)
        all_follows(*args, **kwargs).filter_map(&:followable)
      end

      def following_by_type(followable_type, *args, **kwargs)
        klass = resolve_class(followable_type)
        relation = klass.joins(:followings).where(
          follows: {
            blocked: false,
            follower_id: id,
            follower_type: parent_class_name(self),
            followable_type: klass.base_class.name
          }
        )
        apply_options_to_scope(relation, merge_options(args, kwargs))
      end

      def following_by_type_count(followable_type)
        klass = resolve_class(followable_type)
        scope = follows.unblocked.where(followable_type: klass.base_class.name)
        scope = scope.where(followable_id: klass.select(:id)) if klass != klass.base_class
        scope.count
      end

      def method_missing(method_name, *args, **kwargs, &block)
        kind, fragment = follower_dynamic_call(method_name)
        case kind
        when :count
          following_by_type_count(fragment.singularize.classify)
        when :list
          following_by_type(fragment.singularize.classify, *args, **kwargs)
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        follower_dynamic_call(method_name).present? || super
      end

      def get_follow(followable)
        follows.unblocked.for_followable(followable).order(id: :desc).take
      end

      private

      def follower_dynamic_call(method_name)
        name = -method_name.to_s
        if (match = FOLLOWING_COUNT.match(name))
          [:count, match[1]]
        elsif (match = FOLLOWING_LIST.match(name))
          [:list, match[1]]
        end
      end
    end
  end
end
