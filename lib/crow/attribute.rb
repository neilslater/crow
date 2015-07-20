module Crow
  class Attribute
    CTYPES = Hash[
      :int => [ 'Int', 'P_Int' ],
      :float => [ 'Float', 'P_Float' ],
      :double => [ 'Double', 'P_Double' ],
      :char => [ 'Char', 'P_Char' ],
      :VALUE => [ 'Value', 'Value' ],
      :NARRAY_FLOAT => [ 'NArrayFloat', 'NArrayFloat' ],
      :NARRAY_DOUBLE => [ 'NArrayDouble', 'NArrayDouble' ],
      :NARRAY_INT => [ 'NArrayInt', 'NArrayInt' ],
      :NARRAY_LONG => [ 'NArrayLong', 'NArrayLong' ],
      :long => [ 'Long', 'P_Long' ],
      :uint => [ 'UInt', 'P_UInt' ],
      :ulong => [ 'ULong', 'P_ULong' ],
    ]

    attr_reader :name, :ctype, :pointer, :default

    def initialize name, opts = {}
      raise "Variable name '#{name}' cannot be used" if name !~ /\A[a-zA-Z0-9_]+\z/
      @name = name
      @default = opts[:default] || self.class.default
      @pointer = !! opts[:pointer]
      @ctype = opts[:ctype]
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

    def cast
      "(#{cbase}#{pointer_star})"
    end

    def is_narray?
      false
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

  class Attribute::Int < Attribute
    include NotA_C_Pointer
    self.default = '0'

    def cbase
      "int"
    end
  end

  class Attribute::P_Int < Attribute
    include IsA_C_Pointer
    self.default = 'NULL'
    self.item_default = '0'

    def cbase
      "int"
    end
  end

  class Attribute::UInt < Attribute::Int
    include NotA_C_Pointer

    self.default = '0'

    def cbase
      "unsigned int"
    end
  end

  class Attribute::P_UInt < Attribute
    include IsA_C_Pointer
    self.default = 'NULL'
    self.item_default = '0'

    def cbase
      "unsigned int"
    end
  end

  class Attribute::Long < Attribute
    include NotA_C_Pointer

    self.default = '0L'

    def cbase
      "long"
    end
  end

  class Attribute::P_Long < Attribute
    include IsA_C_Pointer
    self.default = 'NULL'
    self.item_default = '0L'

    def cbase
      "long"
    end
  end

  class Attribute::ULong < Attribute::Long
    include NotA_C_Pointer
    self.default = '0L'

    def cbase
      "unsigned long"
    end
  end

  class Attribute::P_ULong < Attribute
    include IsA_C_Pointer
    self.default = 'NULL'
    self.item_default = '0L'

    def cbase
      "unsigned long"
    end
  end

  class Attribute::Float < Attribute
    include NotA_C_Pointer
    self.default = '0.0'

    def cbase
      "float"
    end
  end

  class Attribute::P_Float < Attribute
    include IsA_C_Pointer
    self.default = 'NULL'
    self.item_default = '0.0'

    def cbase
      "float"
    end
  end

  class Attribute::Double < Attribute
    include NotA_C_Pointer
    self.default = '0.0'

    def cbase
      "double"
    end
  end

  class Attribute::P_Double < Attribute
    include IsA_C_Pointer
    self.default = 'NULL'
    self.item_default = '0.0'

    def cbase
      "double"
    end
  end

  class Attribute::Char < Attribute
    include NotA_C_Pointer
    self.default = '0'

    def cbase
      "char"
    end
  end

  class Attribute::P_Char < Attribute
    include IsA_C_Pointer
    self.default = 'NULL'
    self.item_default = '0'

    def cbase
      "char"
    end
  end

  class Attribute::Value < Attribute
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
  end

  class Attribute::NArray < Attribute::Value
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
  end

  class Attribute::NArrayFloat < Attribute::NArray
    include NotA_C_Pointer
    self.default = 'Qnil'
    self.item_default = '0.0'

    def item_ctype
      'float'
    end

    def narray_enum_type
      'NA_SFLOAT'
    end
  end

  class Attribute::NArrayDouble < Attribute::NArray
    include NotA_C_Pointer
    self.default = 'Qnil'
    self.item_default = '0.0'

    def item_ctype
      'double'
    end

    def narray_enum_type
      'NA_FLOAT'
    end
  end

  class Attribute::NArrayInt < Attribute::NArray
    include NotA_C_Pointer
    self.default = 'Qnil'
    self.item_default = '0'

    def item_ctype
      'int'
    end

    def narray_enum_type
      'NA_INT'
    end
  end

  class Attribute::NArrayLong < Attribute::NArray
    include NotA_C_Pointer
    self.default = 'Qnil'
    self.item_default = '0'

    def item_ctype
      'long'
    end

    def narray_enum_type
      'NA_LONG'
    end
  end
end
