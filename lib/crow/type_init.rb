# frozen_string_literal: true

require 'set'

module Crow
  # This class describes initialisation properties for simple data elements within a
  # struct container. An instance of this class describes specific initialisation options that
  # can then be rendered into C code for validationa or setting values in project files.
  #
  class TypeInit
    # The default value, assigned when nothing else provided.
    # @return [String]
    attr_reader :default

    # The containing type description.
    # @return [Crow::TypeMap]
    attr_reader :parent_typemap

    # The initialising expression (in C syntax) for single value or for all data elements in an array.
    # @return [String]
    attr_reader :expr

    # The initialising expression for array size (in C syntax), applicable if data type is a pointer.
    # @return [String]
    attr_reader :size_expr

    # The initialising expression for array shape (in C syntax), applicable if data type is NArray.
    # @return [String]
    attr_reader :shape_expr

    # The initialising expressions for array shape (in C syntax), applicable if data type is NArray.
    # @return [Array<String>]
    attr_reader :shape_exprs

    # The initialising expression for array rank (in C syntax), applicable if data type is NArray.
    # @return [String]
    attr_reader :rank_expr

    # The minimum acceptable value.
    # @return [String]
    attr_reader :validate_min

    # The maximum acceptable value.
    # @return [String]
    attr_reader :validate_max

    def initialize(parent_typemap:, default: parent_typemap.class.default, size_expr: nil,
                   shape_expr: nil, shape_exprs: nil, rank_expr: nil, expr: nil, validate_min: nil,
                   validate_max: nil)
      @default = default
      raise ArgumentError, 'parent_typemap must be a Crow::TypeMap' unless parent_typemap.is_a? Crow::TypeMap

      init_expressions(
        size_expr: size_expr, shape_expr: shape_expr, shape_exprs: shape_exprs, rank_expr: rank_expr, expr: expr
      )

      @parent_typemap = parent_typemap
      @validate_min ||= validate_min
      @validate_max ||= validate_max
    end

    def validate?
      validate_min || validate_max
    end

    def validate_condition_c(var_c = parent_typemap.struct_item)
      return '( 1 )' unless validate?

      if validate_min && validate_max
        "( #{var_c} >= #{validate_min} && #{var_c} <= #{validate_max} )"
      elsif validate_min
        "( #{var_c} >= #{validate_min} )"
      else
        "( #{var_c} <= #{validate_max} )"
      end
    end

    def validate_fail_condition_c(var_c = parent_typemap.struct_item)
      return '( 0 )' unless validate?

      if validate_min && validate_max
        "( #{var_c} < #{validate_min} || #{var_c} > #{validate_max} )"
      elsif validate_min
        "( #{var_c} < #{validate_min} )"
      else
        "( #{var_c} > #{validate_max} )"
      end
    end

    # This class describes initialisation properties for pointer data elements within a
    # struct container. An instance of this class describes specific initialisation options that
    # can then be rendered into C code for validationa or setting values in project files.
    #
    class Pointer < TypeInit
      def initialize(opts = {})
        super(opts)
        @expr ||= parent_typemap.class.item_default
      end

      def size_expr_c(from: parent_typemap.parent_struct.short_name, init_context: false)
        struct = parent_typemap.parent_struct
        e = Expression.new(use_size_expr(init_context), struct.attributes, struct.init_params)
        e.as_c_code(from)
      end

      private

      def use_size_expr(init_context)
        use_size_expr = size_expr

        if size_expr.start_with?('.')
          use_size_expr = if init_context
                            size_expr.sub('.', '$')
                          else
                            size_expr.sub('.', '%')
                          end
        end

        use_size_expr
      end
    end

    # This class describes initialisation properties for narray data elements within a
    # struct container. An instance of this class describes specific initialisation options that
    # can then be rendered into C code for validationa or setting values in project files.
    #
    class NArray < TypeInit
      def initialize(opts = {})
        super(opts)
        @expr ||= parent_typemap.class.item_default
        if @shape_expr
          # Do nothing
        elsif @shape_exprs
          @shape_expr = parent_typemap.shape_tmp_var
        else
          @shape_expr = "{ #{([1] * rank_expr.to_i).join(', ')} }"
        end
      end

      def shape_expr_c(container_name = parent_typemap.parent_struct.short_name)
        struct = parent_typemap.parent_struct

        allowed_attributes = struct.attributes.clone

        Expression.new(shape_expr, allowed_attributes, struct.init_params).as_c_code(container_name)
      end
    end

    private

    def init_expressions(size_expr:, shape_expr:, shape_exprs:, rank_expr:, expr:)
      @expr ||= expr
      @size_expr ||= size_expr
      @shape_expr ||= shape_expr
      @shape_exprs ||= shape_exprs
      @rank_expr ||= rank_expr
      nil
    end
  end
end
