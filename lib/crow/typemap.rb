# frozen_string_literal: true

require 'set'

module Crow
  # This class represents information about data elements that can be used to create C and Ruby
  # code for that element.
  #
  class TypeMap
    # Key is supported type name, value is array with subclass and pointer subclass names
    CTYPES = Hash[
      int: %w[Int P_Int],
      float: %w[Float P_Float],
      double: %w[Double P_Double],
      char: %w[Char P_Char],
      long: %w[Long P_Long],
      uint: %w[UInt P_UInt],
      ulong: %w[ULong P_ULong],
      VALUE: %w[Value Value],
      NARRAY_FLOAT: %w[NArrayFloat NArrayFloat],
      NARRAY_DOUBLE: %w[NArrayDouble NArrayDouble],
      NARRAY_INT_16: %w[NArraySInt NArraySInt],
      NARRAY_INT_32: %w[NArrayLInt NArrayLInt],
    ]

    # The name of the variable within the struct
    # @return [String]
    attr_reader :name

    # The name of the variable exposed to Ruby
    # @return [String]
    attr_reader :ruby_name

    # Whether this variable is readable from Ruby (if it is a struct atribute)
    # @return [Boolean]
    attr_reader :ruby_read

    # Whether this variable is writable from Ruby (if it is a struct atribute)
    # @return [Boolean]
    attr_reader :ruby_write

    # The C data type of the variable
    # @return [Symbol]
    attr_reader :ctype

    # Whether this variable is a C pointer
    # @return [Boolean]
    attr_reader :pointer

    # The default value to use when initialised without any overrides or input (e.g. when reserving
    # memory for the struct)
    # @return [String]
    attr_reader :default

    # The containing structure for this variable
    # @return [Crow::StructClass]
    attr_reader :parent_struct

    # Initialisation rules
    # @return [Crow::TypeInit]
    attr_reader :init

    # Whether or not to store/restore the value when using save
    # @return [Boolean]
    attr_reader :store

    # Creates a new type mapping description.
    # @param [Hash] opts
    # @option opts [String] :name (required) base name, used as C name inside parent struct
    # @option opts [Crow::StructClass] :parent_struct (required), definition for the containing C struct
    # @option opts [String] :ruby_name if provided then allows for different Ruby name from C name
    # @option opts [String] :default if provided then over-rides default based on class
    # @option opts [Boolean] :pointer false by default, if true augments the type to a C pointer
    # @option opts [Boolean] :ruby_read true by default, if true exposes the field as property of Ruby class wrapper
    # @option opts [Boolean] :ruby_write false by default, if true exposes the field as writable from Ruby class wrapper
    # @option opts [Hash] :init, constructor params for a Crow::TypeInit description for how the value should be set
    # @return [Crow::TypeMap]
    def initialize(name:, ruby_name: name, default: self.class.default, pointer: false, ctype:,
                   init: {}, parent_struct:, ruby_read: true, ruby_write: false, store: self.class.store_default)
      raise "Variable name '#{name}' cannot be used" if name !~ /\A[a-zA-Z0-9_]+\z/

      @name = name
      @ruby_name = ruby_name
      @default = default
      @pointer = !!pointer
      @ctype = ctype
      raise ArgumentError, 'parent_struct must be a Crow::StructClass' unless parent_struct.is_a? Crow::StructClass

      @parent_struct = parent_struct
      @init = init_class.new(init.merge(parent_typemap: self))
      @ruby_read = !!ruby_read
      @ruby_write = !!ruby_write
      @store = !!store
    end

    def init_class
      Crow::TypeInit
    end

    def self.create(opts = {})
      unless class_lookup = CTYPES[opts[:ctype]]
        raise ArgumentError, "Type '#{opts[:ctype]}' not supported. Allowed types #{CTYPES.keys.join(', ')}"
      end

      attribute_class = if opts[:pointer]
                          class_lookup.last
                        else
                          class_lookup.first
      end

      const_get(attribute_class).new(opts)
    end

    def self.default
      @class_default
    end

    def self.default=(new_default)
      @class_default = new_default
    end

    def self.item_default
      @class_item_default
    end

    def self.item_default=(new_default)
      @class_item_default = new_default
    end

    def self.store_default
      true
    end

    def needs_gc_mark?
      false
    end

    def pointer_star
      pointer ? '*' : ''
    end

    def declare
      "#{cbase} #{pointer_star}#{name};"
    end

    def as_param
      "#{cbase} #{pointer_star}#{name}"
    end

    def cast
      "(#{cbase}#{pointer_star})"
    end

    def is_narray?
      false
    end

    def rv_name
      "rv_#{name}"
    end

    def as_rv_param
      "VALUE rv_#{name}"
    end

    def struct_item
      "#{parent_struct.short_name}->#{name}"
    end

    def struct_item_to_ruby
      self.class.c_to_ruby(struct_item)
    end

    def param_item_to_c
      self.class.ruby_to_c(rv_name)
    end

    def init_expr_c(from: parent_struct.short_name, init_context: false)
      use_expr = init.expr

      if init.expr == '.'
        use_expr = if init_context
                     "$#{name}"
                   else
                     "%#{name}"
                   end
      end

      e = Expression.new(use_expr, @parent_struct.attributes, @parent_struct.init_params)
      e.as_c_code(from)
    end

    def needs_init?
      !!init.expr
    end

    def validate?
      init.validate?
    end

    def validate_condition_c(var_c = struct_item)
      init.validate_condition_c var_c
    end

    def validate_fail_condition_c(var_c = struct_item)
      init.validate_fail_condition_c var_c
    end

    def needs_simple_init?
      needs_init? && !is_narray? && !pointer
    end

    def read_only?
      ruby_read && !ruby_write
    end

    def min_valid
      init.validate_min || 1
    end

    def test_value(init_context: true)
      return default if init.expr.nil?

      use_expr = init.expr

      if init.expr == '.'
        use_expr = if init_context
                     "$#{name}"
                   else
                     "%#{name}"
                   end
      end

      e = Expression.new(use_expr, @parent_struct.attributes, @parent_struct.init_params)
      e.as_ruby_test_value
    end
  end

  module NotA_C_Pointer
    def needs_alloc?
      false
    end
  end

  module IsA_C_Pointer
    def needs_alloc?
      true
    end

    def init_class
      Crow::TypeInit::Pointer
    end

    def initialize(opts = {})
      super(opts)

      @ruby_read = opts[:ruby_read].nil? ? true : opts[:ruby_read]
      @ruby_write = opts[:ruby_write].nil? ? false : opts[:ruby_write]
    end
  end
end

# These need to be at end to refer the mixins above, and are not part of
require_relative 'typemap_basic_types'
require_relative 'typemap_pointers'
require_relative 'typemap_narray'
