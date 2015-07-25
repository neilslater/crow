module Crow
  class TypeMap
    CTYPES = Hash[
      :int => [ 'Int', 'P_Int' ],
      :float => [ 'Float', 'P_Float' ],
      :double => [ 'Double', 'P_Double' ],
      :char => [ 'Char', 'P_Char' ],
      :VALUE => [ 'Value', 'Value' ],
      :NARRAY_FLOAT => [ 'NArrayFloat', 'NArrayFloat' ],
      :NARRAY_DOUBLE => [ 'NArrayDouble', 'NArrayDouble' ],
      :NARRAY_INT_16 => [ 'NArraySInt', 'NArraySInt' ],
      :NARRAY_INT_32 => [ 'NArrayLInt', 'NArrayLInt' ],
      :long => [ 'Long', 'P_Long' ],
      :uint => [ 'UInt', 'P_UInt' ],
      :ulong => [ 'ULong', 'P_ULong' ],
    ]

    attr_reader :name, :ctype, :pointer, :default, :parent_struct

    def initialize name, opts = {}
      raise "Variable name '#{name}' cannot be used" if name !~ /\A[a-zA-Z0-9_]+\z/
      @name = name
      @default = opts[:default] || self.class.default
      @pointer = !! opts[:pointer]
      @ctype = opts[:ctype]
      @parent_struct = opts[:parent_struct]
    end

    def self.create name, opts = {}
      class_lookup = CTYPES[ opts[:ctype] ]
      raise "Type '#{opts[:ctype]}' not supported. Allowed types #{CTYPES.keys.join(', ')}" unless class_lookup
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

    attr_reader :size_expr, :init_expr

    def initialize name, opts = {}
      super( name, opts )
      @size_expr = opts[:size_expr] || @name.upcase + '_SIZE'
      @init_expr = opts[:init_expr] || self.class.item_default
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
      "VALUE"
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

    attr_reader :rank_expr, :shape_expr, :init_expr

    def initialize name, opts = {}
      super( name, opts )
      @rank_expr = opts[:rank_expr] || @name.upcase + '_RANK'
      @shape_expr = opts[:shape_expr] || @name.upcase + '_SHAPE'
      @init_expr = opts[:init_expr] || self.class.item_default
    end

    def is_narray?
      true
    end

    def rdoc_type
      'NArray'
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
