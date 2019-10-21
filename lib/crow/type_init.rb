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

    # TODO: This should be a subclass thing . . .
    def narray_post_init shape_var = nil
      @expr ||= parent_typemap.class.item_default
      if ( shape_var )
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
  end
end
