require 'set'

module Crow
  class TypeInit
    attr_reader :default, :parent_typemap, :init_expr, :size_expr, :shape_expr, :shape_exprs, :rank_expr

    def initialize(parent_typemap:, default: parent_typemap.class.default, size_expr: nil, shape_expr: nil, shape_exprs: nil, rank_expr: nil, init_expr: nil)
      @default = default
      unless parent_typemap.is_a? Crow::TypeMap
        raise ArgumentError, "parent_typemap must be a Crow::TypeMap"
      end
      @parent_typemap = parent_typemap
      @init_expr ||= init_expr
      @size_expr ||= size_expr
      @shape_expr ||= shape_expr
      @shape_exprs ||= shape_exprs
      @rank_expr ||= rank_expr
    end
  end
end
