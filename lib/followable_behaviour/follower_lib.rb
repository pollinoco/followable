module FollowableBehaviour
  module FollowerLib

    private

    # Retrieves the parent class name if using STI.
    def parent_class_name(obj)
      obj.class.base_class.name
    end

    def apply_options_to_scope(scope, options = {})
      if options.has_key?(:limit)
        scope = scope.limit(options[:limit])
      end
      if options.has_key?(:includes)
        scope = scope.includes(options[:includes])
      end
      if options.has_key?(:joins)
        scope = scope.joins(options[:joins])
      end
      if options.has_key?(:where)
        scope = scope.where(options[:where])
      end
      if options.has_key?(:order)
        scope = scope.order(options[:order])
      end
      scope
    end
  end
end
