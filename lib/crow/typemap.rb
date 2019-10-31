require 'set'

module Crow
  class TypeMap
    CTYPES = Hash[
      :int => [ 'Int', 'P_Int' ],
      :float => [ 'Float', 'P_Float' ],
      :double => [ 'Double', 'P_Double' ],
      :char => [ 'Char', 'P_Char' ],
      :long => [ 'Long', 'P_Long' ],
      :uint => [ 'UInt', 'P_UInt' ],
      :ulong => [ 'ULong', 'P_ULong' ],
      :VALUE => [ 'Value', 'Value' ],
      :NARRAY_FLOAT => [ 'NArrayFloat', 'NArrayFloat' ],
      :NARRAY_DOUBLE => [ 'NArrayDouble', 'NArrayDouble' ],
      :NARRAY_INT_16 => [ 'NArraySInt', 'NArraySInt' ],
      :NARRAY_INT_32 => [ 'NArrayLInt', 'NArrayLInt' ],
    ]

    attr_reader :name, :ruby_name, :ctype, :pointer, :default, :parent_struct, :init
    attr_reader :ruby_read, :ruby_write, :ptr_cache, :shape_var

    def initialize(name:, ruby_name: name, default: self.class.default, pointer: false, ctype:,
                   init: {}, parent_struct:, ruby_read: true, ruby_write: false, shape_var: nil, ptr_cache: nil)
      raise "Variable name '#{name}' cannot be used" if name !~ /\A[a-zA-Z0-9_]+\z/
      @name = name
      @ruby_name = ruby_name
      @default = default
      @pointer = !! pointer
      @ctype = ctype
      unless parent_struct.is_a? Crow::StructClass
        raise ArgumentError, "parent_struct must be a Crow::StructClass"
      end
      @parent_struct = parent_struct
      @init = init_class.new( init.merge(parent_typemap: self) )
      @ruby_read = !! ruby_read
      @ruby_write = !! ruby_write
    end

    def init_class
      Crow::TypeInit
    end

    def self.create opts = {}
      unless class_lookup = CTYPES[ opts[:ctype] ]
        raise ArgumentError, "Type '#{opts[:ctype]}' not supported. Allowed types #{CTYPES.keys.join(', ')}"
      end

      attribute_class = if opts[:pointer]
          class_lookup.last
        else
          class_lookup.first
      end

      self.const_get( attribute_class ).new( opts )
    end

    def self.default
      @class_default
    end

    def self.default= new_default
      @class_default = new_default
    end

    def self.item_default
      @class_item_default
    end

    def self.item_default= new_default
      @class_item_default = new_default
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
      self.class.c_to_ruby( struct_item )
    end

    def param_item_to_c
      self.class.ruby_to_c( rv_name )
    end

    def init_expr_c from: parent_struct.short_name, init_context: false
      use_expr = init.expr

      if init.expr == '.'
        if init_context
          use_expr = "$#{self.name}"
        else
          use_expr = "%#{self.name}"
        end
      end

      e = Expression.new( use_expr, @parent_struct.attributes, @parent_struct.init_params )
      e.as_c_code( from )
    end

    def needs_init?
      !! init.expr
    end

    def needs_simple_init?
      needs_init? && ! is_narray? && ! pointer
    end

    def read_only?
      ruby_read && ! ruby_write
    end

    def declare_ptr_cache struct_name = parent_struct.short_name
      "#{item_ctype} *#{ptr_cache};"
    end

    def init_ptr_cache struct_name = parent_struct.short_name
      "#{struct_name}->#{ptr_cache} = NULL"
    end

    def set_ptr_cache struct_name = parent_struct.short_name
      "#{struct_name}->#{ptr_cache} = (#{item_ctype} *) #{struct_name}->#{name}->ptr"
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

    def initialize opts = {}
      super( opts )

      @ruby_read = opts[:ruby_read].nil? ? true : opts[:ruby_read]
      @ruby_write = opts[:ruby_write].nil? ? false : opts[:ruby_write]
    end
  end

  require_relative 'typemap_basic_types'
  require_relative 'typemap_pointers'
  require_relative 'typemap_narray'
end
