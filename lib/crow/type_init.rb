require 'set'

module Crow
  class TypeInit
    attr_reader :default, :parent_typemap, :expr, :size_expr, :shape_expr, :shape_exprs, :rank_expr

    def initialize(parent_typemap:, default: parent_typemap.class.default, size_expr: nil, shape_expr: nil, shape_exprs: nil, rank_expr: nil, expr: nil)
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
      if ( shape_var = parent_typemap.shape_var )
        @shape_expr = "%#{shape_var}"
        @shape_exprs ||= [1] * rank_expr.to_i
      else
        if @shape_expr
          # Do nothing
        elsif @shape_exprs
          @shape_expr = parent_typemap.parent_struct.short_name + '_'  + parent_typemap.name + '_shape'
        else
          @shape_expr = "{ #{([1] * rank_expr.to_i).join(', ')} }"
        end
      end
    end

    def shape_expr_c container_name = parent_typemap.parent_struct.short_name
      struct = parent_typemap.parent_struct

      allowed_attributes = struct.attributes.clone
      if parent_typemap.shape_var
        allowed_attributes << TypeMap::P_Int.new( name: parent_typemap.shape_var, parent_struct: struct, ctype: :int )
      end

      Expression.new( shape_expr, allowed_attributes, struct.init_params ).as_c_code( container_name )
    end
  end
end
