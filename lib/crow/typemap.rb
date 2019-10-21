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

    def initialize(n, name: n, ruby_name: name, default: self.class.default, pointer: false, ctype:,
                   init: {}, parent_struct:, ruby_read: true, ruby_write: false,
                   shape_var: nil, ptr_cache: nil)
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
      @init = Crow::TypeInit.new( init.merge(parent_typemap: self) )
      @ruby_read = !! ruby_read
      @ruby_write = !! ruby_write
    end

    def self.create name, opts = {}
      unless class_lookup = CTYPES[ opts[:ctype] ]
        raise ArgumentError, "Type '#{opts[:ctype]}' not supported. Allowed types #{CTYPES.keys.join(', ')}"
      end

      attribute_class = if opts[:pointer]
          class_lookup.last
        else
          class_lookup.first
      end

      self.const_get( attribute_class ).new( name, opts )
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

    def initialize name, opts = {}
      super( name, opts )
      init.pointer_post_init

      @ruby_read = opts[:ruby_read].nil? ? true : opts[:ruby_read]
      @ruby_write = opts[:ruby_write].nil? ? false : opts[:ruby_write]
    end
  end

  class TypeMap::Int < TypeMap
    include NotA_C_Pointer
    self.default = '0'

    def cbase
      "int"
    end

    def rdoc_type
      'Integer'
    end

    def self.ruby_to_c ruby_name
      "NUM2INT( #{ruby_name} )"
    end

    def self.c_to_ruby c_name
      "INT2NUM( #{c_name} )"
    end
  end

  class TypeMap::P_Int < TypeMap
    include IsA_C_Pointer
    self.default = 'NULL'
    self.item_default = '0'

    def cbase
      "int"
    end

    def rdoc_type
      'Array<Integer>'
    end

    def array_item_to_ruby_converter
      'INT2NUM'
    end
  end

  class TypeMap::UInt < TypeMap::Int
    include NotA_C_Pointer

    self.default = '0'

    def cbase
      "unsigned int"
    end

    def rdoc_type
      'Integer'
    end

    def self.ruby_to_c ruby_name
      "NUM2UINT( #{ruby_name} )"
    end

    def self.c_to_ruby c_name
      "UINT2NUM( #{c_name} )"
    end
  end

  class TypeMap::P_UInt < TypeMap
    include IsA_C_Pointer
    self.default = 'NULL'
    self.item_default = '0'

    def cbase
      "unsigned int"
    end

    def rdoc_type
      'Array<Integer>'
    end

    def array_item_to_ruby_converter
      'UINT2NUM'
    end
  end

  class TypeMap::Long < TypeMap
    include NotA_C_Pointer

    self.default = '0L'

    def cbase
      "long"
    end

    def rdoc_type
      'Integer'
    end

    def self.ruby_to_c ruby_name
      "NUM2LONG( #{ruby_name} )"
    end

    def self.c_to_ruby c_name
      "LONG2NUM( #{c_name} )"
    end
  end

  class TypeMap::P_Long < TypeMap
    include IsA_C_Pointer
    self.default = 'NULL'
    self.item_default = '0L'

    def cbase
      "long"
    end

    def rdoc_type
      'Integer'
    end

    def array_item_to_ruby_converter
      'LONG2NUM'
    end
  end

  class TypeMap::ULong < TypeMap::Long
    include NotA_C_Pointer
    self.default = '0L'

    def cbase
      "unsigned long"
    end

    def rdoc_type
      'Integer'
    end

    def self.ruby_to_c ruby_name
      "NUM2ULONG( #{ruby_name} )"
    end

    def self.c_to_ruby c_name
      "ULONG2NUM( #{c_name} )"
    end
  end

  class TypeMap::P_ULong < TypeMap
    include IsA_C_Pointer
    self.default = 'NULL'
    self.item_default = '0L'

    def cbase
      "unsigned long"
    end

    def rdoc_type
      'Array<Integer>'
    end

    def array_item_to_ruby_converter
      'ULONG2NUM'
    end
  end

  class TypeMap::Float < TypeMap
    include NotA_C_Pointer
    self.default = '0.0'

    def cbase
      "float"
    end

    def rdoc_type
      'Float'
    end

    def self.ruby_to_c ruby_name
      "NUM2FLT( #{ruby_name} )"
    end

    def self.c_to_ruby c_name
      "FLT2NUM( #{c_name} )"
    end
  end

  class TypeMap::P_Float < TypeMap
    include IsA_C_Pointer
    self.default = 'NULL'
    self.item_default = '0.0'

    def cbase
      "float"
    end

    def rdoc_type
      'Array<Float>'
    end

    def array_item_to_ruby_converter
      'FLT2NUM'
    end
  end

  class TypeMap::Double < TypeMap
    include NotA_C_Pointer
    self.default = '0.0'

    def cbase
      "double"
    end

    def rdoc_type
      'Float'
    end

    def self.ruby_to_c ruby_name
      "NUM2DBL( #{ruby_name} )"
    end

    def self.c_to_ruby c_name
      "DBL2NUM( #{c_name} )"
    end
  end

  class TypeMap::P_Double < TypeMap
    include IsA_C_Pointer
    self.default = 'NULL'
    self.item_default = '0.0'

    def cbase
      "double"
    end

    def rdoc_type
      'Array<Float>'
    end

    def array_item_to_ruby_converter
      'DBL2NUM'
    end
  end

  class TypeMap::Char < TypeMap
    include NotA_C_Pointer
    self.default = '0'

    def cbase
      "char"
    end

    def rdoc_type
      'Byte'
    end

    def self.ruby_to_c ruby_name
      "NUM2CHR( #{ruby_name} )"
    end

    def self.c_to_ruby c_name
      "LONG2FIX( #{c_name} )"
    end
  end

  class TypeMap::P_Char < TypeMap
    include IsA_C_Pointer
    self.default = 'NULL'
    self.item_default = '0'

    def cbase
      "char"
    end

    def rdoc_type
      'String'
    end
  end

  class TypeMap::Value < TypeMap
    include NotA_C_Pointer
    self.default = 'Qnil'

    def cbase
      "volatile VALUE"
    end

    def needs_gc_mark?
      true
    end

    def cast
      "ERROR"
    end

    def rdoc_type
      'Object'
    end

    def self.ruby_to_c ruby_name
      ruby_name
    end

    def self.c_to_ruby c_name
      c_name
    end
  end

  class TypeMap::NArray < TypeMap::Value
    include NotA_C_Pointer
    self.default = 'Qnil'

    attr_reader :shape_tmp_var

    def initialize name, opts = {}
      super( name, opts )
      init.narray_post_init(opts[:shape_var])

      if ( opts[:shape_var] )
        @shape_var = opts[:shape_var]
      else
        if opts[:init] && opts[:init][:shape_expr]
          # Do nothing
        elsif opts[:init] && opts[:init][:shape_exprs]
          @shape_tmp_var = @parent_struct.short_name + '_'  + @name + '_shape'
        else
          # Do nothing
        end
      end

      @ptr_cache = opts[:ptr_cache]
    end

    def is_narray?
      true
    end

    def rdoc_type
      'NArray'
    end

    def declare_ptr_cache
      "#{item_ctype} *#{ptr_cache};"
    end

    def init_ptr_cache struct_name = parent_struct.short_name
      "#{struct_name}->#{ptr_cache} = NULL"
    end

    def set_ptr_cache struct_name = parent_struct.short_name, narray_var = 'narr'
      "#{struct_name}->#{ptr_cache} = (#{item_ctype} *) #{narray_var}->ptr"
    end

    def declare_shape_var
      "int *#{shape_var};"
    end

    def init_shape_var struct_name = parent_struct.short_name
      "#{struct_name}->#{shape_var} = NULL"
    end
  end

  class TypeMap::NArrayFloat < TypeMap::NArray
    include NotA_C_Pointer
    self.default = 'Qnil'
    self.item_default = '0.0'

    def item_ctype
      'float'
    end

    def narray_enum_type
      'NA_SFLOAT'
    end

    def rdoc_type
      'NArray<sfloat>'
    end
  end

  class TypeMap::NArrayDouble < TypeMap::NArray
    include NotA_C_Pointer
    self.default = 'Qnil'
    self.item_default = '0.0'

    def item_ctype
      'double'
    end

    def narray_enum_type
      'NA_DFLOAT'
    end

    def rdoc_type
      'NArray<float>'
    end
  end

  class TypeMap::NArraySInt < TypeMap::NArray
    include NotA_C_Pointer
    self.default = 'Qnil'
    self.item_default = '0'

    def item_ctype
      'int16_t'
    end

    def narray_enum_type
      'NA_SINT'
    end

    def rdoc_type
      'NArray<sint>'
    end
  end

  class TypeMap::NArrayLInt < TypeMap::NArray
    include NotA_C_Pointer
    self.default = 'Qnil'
    self.item_default = '0'

    def item_ctype
      'int32_t'
    end

    def narray_enum_type
      'NA_LINT'
    end

    def rdoc_type
      'NArray<int>'
    end
  end
end
