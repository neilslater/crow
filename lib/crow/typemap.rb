# frozen_string_literal: true

require 'set'

module Crow
  # This module define the base conversions to C or Ruby code snippets for TypeMap classes.
  #
  module TypeMapCodeSnippets
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

    def validate_condition_c(var_c = struct_item)
      init.validate_condition_c var_c
    end

    def validate_fail_condition_c(var_c = struct_item)
      init.validate_fail_condition_c var_c
    end

    def init_expr_c(from: parent_struct.short_name, init_context: false)
      e = Expression.new(use_expr(init_context), @parent_struct.attributes, @parent_struct.init_params)
      e.as_c_code(from)
    end
  end

  # This class represents information about data elements that can be used to create C and Ruby
  # code for that element.
  #
  class TypeMap
    include TypeMapCodeSnippets

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
    # @param [String] name (required) base name, used as C name inside parent struct
    # @param [Crow::StructClass] parent_struct (required), definition for the containing C struct
    # @param [String] ruby_name if provided then allows for different Ruby name from C name
    # @param [String] default if provided then over-rides default based on class
    # @param [Boolean] pointer false by default, if true augments the type to a C pointer
    # @param [Boolean] ruby_read true by default, if true exposes the field as property of Ruby class wrapper
    # @param [Boolean] ruby_write false by default, if true exposes the field as writable from Ruby class wrapper
    # @param [Hash] init constructor params for a Crow::TypeInit description for how the value should be set
    # @return [Crow::TypeMap]
    def initialize(name:, ctype:, parent_struct:, ruby_name: name, default: self.class.default, pointer: false,
                   init: {}, ruby_read: true, ruby_write: false, store: self.class.store_default)
      check_init_args(name, parent_struct)
      basic_attributes(name: name, ruby_name: ruby_name, default: default, pointer: pointer, ctype: ctype)

      @parent_struct = parent_struct
      @init = init_class.new(**init.merge(parent_typemap: self))
      @ruby_read = ruby_read
      @ruby_write = ruby_write
      @store = store
    end

    def init_class
      TypeInit
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

    def narray?
      false
    end

    def needs_init?
      !!init.expr
    end

    def validate?
      init.validate?
    end

    def needs_simple_init?
      needs_init? && !narray? && !pointer
    end

    def read_only?
      ruby_read && !ruby_write
    end

    def min_valid
      init.validate_min || 1
    end

    def test_value(init_context: true)
      return default if init.expr.nil?

      e = Expression.new(use_expr(init_context), @parent_struct.attributes, @parent_struct.init_params)
      e.as_ruby_test_value
    end

    private

    def basic_attributes(name:, ruby_name:, default:, pointer:, ctype:)
      @name = name
      @ruby_name = ruby_name
      @default = default
      @pointer = pointer
      @ctype = ctype
    end

    def check_init_args(name, parent_struct)
      raise "Variable name '#{name}' cannot be used" if name !~ /\A[a-zA-Z0-9_]+\z/

      raise ArgumentError, 'parent_struct must be a Crow::StructClass' unless parent_struct.is_a? Crow::StructClass
    end

    def use_expr(init_context)
      use_expr = init.expr

      if init.expr == '.'
        use_expr = if init_context
                     "$#{name}"
                   else
                     "%#{name}"
                   end
      end

      use_expr
    end
  end

  # Mixin for classes that represent non-pointer data types.
  #
  module NotACPointer
    def needs_alloc?
      false
    end
  end

  # Mixin for classes that represent pointer data types.
  #
  module IsACPointer
    def needs_alloc?
      true
    end

    def init_class
      Crow::TypeInit::Pointer
    end

    def initialize(opts = {})
      super(**opts)

      @ruby_read = opts[:ruby_read].nil? ? true : opts[:ruby_read]
      @ruby_write = opts[:ruby_write].nil? ? false : opts[:ruby_write]
    end
  end

  # This class constructs valid TypeMaps from hash description.
  #
  class TypeMapFactory
    require_relative 'typemap_basic_types'
    require_relative 'typemap_pointers'
    require_relative 'typemap_narray'

    # Key is supported type name, value is array with subclass and pointer subclass names
    CTYPES = { int: [TypeMap::Int, TypeMap::PointerInt],
               float: [TypeMap::Float, TypeMap::PointerFloat],
               double: [TypeMap::Double, TypeMap::PointerDouble],
               char: [TypeMap::Char, TypeMap::PointerChar],
               long: [TypeMap::Long, TypeMap::PointerLong],
               uint: [TypeMap::UInt, TypeMap::PointerUInt],
               ulong: [TypeMap::ULong, TypeMap::PointerULong],
               VALUE: [TypeMap::Value, TypeMap::Value],
               NARRAY_FLOAT: [TypeMap::NArrayFloat, TypeMap::NArrayFloat],
               NARRAY_DOUBLE: [TypeMap::NArrayDouble, TypeMap::NArrayDouble],
               NARRAY_INT_16: [TypeMap::NArraySInt, TypeMap::NArraySInt],
               NARRAY_INT_32: [TypeMap::NArrayLInt, TypeMap::NArrayLInt] }.freeze

    def self.create_typemap(opts = {})
      unless (class_lookup = CTYPES[opts[:ctype]])
        raise ArgumentError, "Type '#{opts[:ctype]}' not supported. Allowed types #{CTYPES.keys.join(', ')}"
      end

      attribute_class = if opts[:pointer]
                          class_lookup.last
                        else
                          class_lookup.first
                        end

      attribute_class.new(**opts)
    end
  end
end
