require 'set'

module Crow
  class TypeInit
    attr_reader :default

    attr_reader :parent_typemap

    attr_reader :expr

    attr_reader :size_expr

    attr_reader :shape_expr

    attr_reader :shape_exprs

    attr_reader :rank_expr

    attr_reader :validate_min

    attr_reader :validate_max

    def initialize(parent_typemap:, default: parent_typemap.class.default, size_expr: nil,
                   shape_expr: nil, shape_exprs: nil, rank_expr: nil, expr: nil, validate_min: nil,
                   validate_max: nil)
      @default = default
      unless parent_typemap.is_a? Crow::TypeMap
        raise ArgumentError, "parent_typemap must be a Crow::TypeMap"
      end
      @parent_typemap = parent_typemap
      @expr ||= expr
      @size_expr ||= size_expr
      @shape_expr ||= shape_expr
      @shape_exprs ||= shape_exprs
      @rank_expr ||= rank_expr
      @validate_min ||= validate_min
      @validate_max ||= validate_max
    end

    def validate?
      validate_min || validate_max
    end

    def validate_condition_c var_c = parent_typemap.struct_item
      return '( 1 )' unless validate?
      if validate_min && validate_max
        "( #{var_c} >= #{validate_min} && #{var_c} <= #{validate_max} )"
      elsif validate_min
        "( #{var_c} >= #{validate_min} )"
      else
        "( #{var_c} <= #{validate_max} )"
      end
    end

    def validate_fail_condition_c var_c = parent_typemap.struct_item
      return '( 0 )' unless validate?
      if validate_min && validate_max
        "( #{var_c} < #{validate_min} || #{var_c} > #{validate_max} )"
      elsif validate_min
        "( #{var_c} < #{validate_min} )"
      else
        "( #{var_c} > #{validate_max} )"
      end
    end
  end

  class TypeInit::Pointer < TypeInit
    def initialize(opts = {})
      super(opts)
      @expr ||= parent_typemap.class.item_default
    end

    def size_expr_c from: parent_typemap.parent_struct.short_name, init_context: false
      use_size_expr = size_expr

      if size_expr.start_with?( '.' )
        if init_context
          use_size_expr = size_expr.sub( '.', '$' )
        else
          use_size_expr = size_expr.sub( '.', '%' )
        end
      end

      struct = parent_typemap.parent_struct
      e = Expression.new( use_size_expr, struct.attributes, struct.init_params )
      e.as_c_code( from )
    end
  end

  class TypeInit::NArray < TypeInit
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

    def shape_expr_c container_name = parent_typemap.parent_struct.short_name
      struct = parent_typemap.parent_struct

      allowed_attributes = struct.attributes.clone

      Expression.new( shape_expr, allowed_attributes, struct.init_params ).as_c_code( container_name )
    end
  end
end
