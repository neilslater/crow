# frozen_string_literal: true

module Crow
  # Defines the base conversions to C or Ruby code snippets for {TypeMap} classes.
  #
  module TypeMapCodeSnippets
    # Pointer declarator used for the mapped C type.
    # @return [String] `*` for pointers, otherwise an empty string
    def pointer_star
      pointer ? '*' : ''
    end

    # C declaration for the mapped variable.
    # @return [String]
    def declare
      "#{cbase} #{pointer_star}#{name};"
    end

    # C parameter declaration for the mapped variable.
    # @return [String]
    def as_param
      "#{cbase} #{pointer_star}#{name}"
    end

    # C cast for the mapped type.
    # @return [String]
    def cast
      "(#{cbase}#{pointer_star})"
    end

    # Name used for the Ruby VALUE corresponding to this variable.
    # @return [String]
    def rv_name
      "rv_#{name}"
    end

    # C parameter declaration for the corresponding Ruby VALUE.
    # @return [String]
    def as_rv_param
      "VALUE rv_#{name}"
    end

    # C expression that accesses this item in its parent struct.
    # @return [String]
    def struct_item
      "#{parent_struct.short_name}->#{name}"
    end

    # C expression that converts this struct item to a Ruby VALUE.
    # @return [String]
    def struct_item_to_ruby
      self.class.c_to_ruby(struct_item)
    end

    # C expression that converts the corresponding Ruby VALUE to this type.
    # @return [String]
    def param_item_to_c
      self.class.ruby_to_c(rv_name)
    end

    # Builds a C condition that accepts values within the configured bounds.
    # @param [String] var_c C expression to validate
    # @return [String]
    def validate_condition_c(var_c = struct_item)
      init.validate_condition_c var_c
    end

    # Builds a C condition that rejects values outside the configured bounds.
    # @param [String] var_c C expression to validate
    # @return [String]
    def validate_fail_condition_c(var_c = struct_item)
      init.validate_fail_condition_c var_c
    end

    # Renders this mapping's initialization expression as C code.
    # @param [String] from C struct variable used for attribute references
    # @param [Boolean] init_context whether dot shorthand refers to an initializer parameter
    # @return [String]
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

    # Whether this variable is readable from Ruby (if it is a struct attribute)
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
    # @param [Symbol] ctype supported C type identifier
    # @param [Crow::StructClass] parent_struct (required), definition for the containing C struct
    # @param [String] ruby_name if provided then allows for different Ruby name from C name
    # @param [String] default if provided then over-rides default based on class
    # @param [Boolean] pointer false by default, if true augments the type to a C pointer
    # @param [Boolean] ruby_read true by default, if true exposes the field as property of Ruby class wrapper
    # @param [Boolean] ruby_write false by default, if true exposes the field as writable from Ruby class wrapper
    # @param [Hash] init constructor params for a Crow::TypeInit description for how the value should be set
    # @param [Boolean] store whether generated persistence helpers include the value
    # @return [Crow::TypeMap]
    # @raise [ArgumentError] if the name is invalid or +parent_struct+ has the wrong type
    def initialize(name:, ctype:, parent_struct:, ruby_name: name, default: self.class.default, pointer: false,
                   init: {}, ruby_read: true, ruby_write: false, store: self.class.store_default?)
      check_init_args(name, parent_struct)
      basic_attributes(name: name, ruby_name: ruby_name, default: default, pointer: pointer, ctype: ctype)

      @parent_struct = parent_struct
      @init = init_class.new(**init, parent_typemap: self)
      @ruby_read = ruby_read
      @ruby_write = ruby_write
      @store = store
    end

    # Initialization-rule class used for this mapping.
    # @return [Class<Crow::TypeInit>]
    def init_class
      TypeInit
    end

    # Default C expression for instances of this mapping class.
    # @return [String, nil]
    def self.default
      @class_default
    end

    # Sets the default C expression for this mapping class.
    # @param [String, nil] new_default
    # @return [String, nil]
    def self.default=(new_default)
      @class_default = new_default
    end

    # Default C expression for elements of pointer or NArray mappings.
    # @return [String, nil]
    def self.item_default
      @class_item_default
    end

    # Sets the default C expression for elements of this mapping class.
    # @param [String, nil] new_default
    # @return [String, nil]
    def self.item_default=(new_default)
      @class_item_default = new_default
    end

    # Whether values of this mapping are persisted by default.
    # @return [Boolean]
    def self.store_default?
      true
    end

    # Whether generated garbage collection code must mark this value.
    # @return [Boolean]
    def needs_gc_mark?
      false
    end

    # Whether this mapping represents a Numo::NArray.
    # @return [Boolean]
    def narray?
      false
    end

    # Whether an initialization expression is configured.
    # @return [Boolean]
    def needs_init?
      !!init.expr
    end

    # Whether validation bounds are configured.
    # @return [Boolean]
    def validate?
      init.validate?
    end

    # Whether this scalar can use the generated simple initialization path.
    # @return [Boolean]
    def needs_simple_init?
      needs_init? && !narray? && !pointer
    end

    # Whether the generated Ruby attribute is readable but not writable.
    # @return [Boolean]
    def read_only?
      ruby_read && !ruby_write
    end

    # Minimum representative value used in generated specs.
    # @return [String, Numeric]
    def min_valid
      init.validate_min || 1
    end

    # Evaluates a representative value for generated specs.
    # @param [Boolean] init_context whether dot shorthand refers to an initializer parameter
    # @return [Object]
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
      raise "Variable name '#{name}' cannot be used" unless /\A[a-zA-Z0-9_]+\z/.match?(name)

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
    # Whether generated code must allocate storage for this mapping.
    # @return [Boolean]
    def needs_alloc?
      false
    end
  end

  # Mixin for classes that represent pointer data types.
  #
  module IsACPointer
    # Whether generated code must allocate storage for this mapping.
    # @return [Boolean]
    def needs_alloc?
      true
    end

    # Initialization-rule class used for pointer mappings.
    # @return [Class<Crow::TypeInit::Pointer>]
    def init_class
      Crow::TypeInit::Pointer
    end

    # Initializes a pointer mapping with pointer-appropriate Ruby visibility defaults.
    # @param [Hash] opts keyword options accepted by {TypeMap#initialize}
    def initialize(opts = {})
      super(**opts)

      @ruby_read = opts[:ruby_read].nil? || opts[:ruby_read]
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
               NARRAY_INT16: [TypeMap::NArraySInt, TypeMap::NArraySInt],
               NARRAY_INT32: [TypeMap::NArrayLInt, TypeMap::NArrayLInt] }.freeze

    # Constructs the appropriate mapping subclass for a C type and pointer flag.
    # @param [Hash] opts options forwarded to {TypeMap#initialize}
    # @option opts [Symbol] :ctype one of the keys in {CTYPES}
    # @option opts [Boolean] :pointer whether to select the pointer mapping subclass
    # @return [Crow::TypeMap]
    # @raise [ArgumentError] if +:ctype+ is unsupported
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
