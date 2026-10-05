# frozen_string_literal: true

module FollowableBehaviour
  module FollowerLib
    PROTECTED_FOLLOW_ATTRIBUTES = %i[
      id followable_id followable_type follower_id follower_type created_at
    ].freeze

    def self.parent_class_name(record)
      record.class.base_class.name
    end

    private

    def parent_class_name(record)
      FollowableBehaviour::FollowerLib.parent_class_name(record)
    end

    def apply_options_to_scope(scope, options = {})
      scope = scope.limit(options[:limit]) if options.key?(:limit)
      scope = scope.offset(options[:offset]) if options.key?(:offset)
      scope = scope.includes(options[:includes]) if options.key?(:includes)
      scope = scope.preload(options[:preload]) if options.key?(:preload)
      scope = scope.joins(options[:joins]) if options.key?(:joins)
      scope = scope.where(options[:where]) if options.key?(:where)
      scope = scope.order(options[:order]) if options.key?(:order)
      scope
    end

    def merge_options(args, kwargs)
      positional = args.last.is_a?(Hash) ? args.last : {}
      positional.merge(kwargs)
    end

    def sanitize_follow_attributes(attributes)
      attributes.except(*PROTECTED_FOLLOW_ATTRIBUTES)
    end

    def apply_follow_attributes(record, attributes)
      return record if attributes.blank?

      record.assign_attributes(attributes)
      record.save! if record.changed?
      record
    end

    def resolve_class(type)
      type.is_a?(Class) ? type : type.to_s.constantize
    end
  end
end
