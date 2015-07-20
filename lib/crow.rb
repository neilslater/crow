require "crow/version"
require 'erb'

module Crow
  class StructClass
    attr_accessor :short_name, :struct_name, :attributes

    TEMPLATE_DIR = File.realdirpath( File.join( __dir__, '../lib/templates' ) )
    TEMPLATES = [ 'ruby_class_dataset.c', 'ruby_class_dataset.h', 'struct_dataset.c', 'struct_dataset.h' ]

    def initialize( short_name, struct_name )
      @short_name = short_name
      @struct_name = struct_name
      @attributes = []
    end

    def write path
      TEMPLATES.each do |template|
        File.open( File.join( path, template.sub( /dataset/, short_name ) ), 'w' ) do |file|
          file.puts render( File.join( TEMPLATE_DIR, template ) )
        end
      end
    end

    private

    def render template_file
      erb = ERB.new( File.read( template_file ) )
      erb.result( binding )
    end
  end

  class Attribute
    CTYPES = Hash[
      :int => [ 'Int', 'P_Int' ],
      :float => [ 'Float', 'P_Float' ],
      :double => [ 'Double', 'P_Double' ],
      :char => [ 'Char', 'P_Char' ],
      :VALUE => [ 'Value', 'Value' ],
      :NARRAY => [ 'NArray', 'NArray' ],
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
      class_lookup.new( name, opts )
    end

    def self.default
      @class_default
    end

    def self.default= new_default
      @class_default = new_default
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
  end

  class Attribute::Int < Attribute
    include NotA_C_Pointer
    default = '0'

    def declare
      "int #{name};"
    end
  end

  class Attribute::P_Int < Attribute
    include IsA_C_Pointer
    default = 'NULL'

    def declare
      "int *#{name};"
    end
  end

  class Attribute::UInt < Attribute::Int
    include NotA_C_Pointer

    default = '0'

    def declare
      "unsigned int #{name};"
    end
  end

  class Attribute::P_UInt < Attribute
    include IsA_C_Pointer

    default = 'NULL'

    def declare
      "unsigned int *#{name};"
    end
  end

  class Attribute::Long < Attribute
    include NotA_C_Pointer

    default = '0L'

    def declare
      "long #{name};"
    end
  end

  class Attribute::P_Long < Attribute
    include IsA_C_Pointer

    default = 'NULL'

    def declare
      "long *#{name};"
    end
  end

  class Attribute::ULong < Attribute::Long
    include NotA_C_Pointer

    default = '0L'

    def declare
      "unsigned long #{name};"
    end
  end

  class Attribute::P_ULong < Attribute
    include IsA_C_Pointer

    default = 'NULL'

    def declare
      "unsigned long *#{name};"
    end
  end

  class Attribute::Float < Attribute
    include NotA_C_Pointer

    self.default = '0.0'

    def declare
      "float #{name};"
    end
  end

  class Attribute::P_Float < Attribute
    include IsA_C_Pointer

    default = 'NULL'

    def declare
      "float *#{name};"
    end
  end

  class Attribute::Double < Attribute
    include NotA_C_Pointer

    default = '0.0'

    def declare
      "double #{name};"
    end
  end

  class Attribute::P_Double < Attribute
    include IsA_C_Pointer

    default = 'NULL'

    def declare
      "double *#{name};"
    end
  end

  class Attribute::Char < Attribute
    include NotA_C_Pointer

    default = '0'

    def declare
      "char #{name};"
    end
  end

  class Attribute::P_Char < Attribute
    include IsA_C_Pointer

    default = 'NULL'

    def declare
      "char *#{name};"
    end
  end

  class Attribute::Value < Attribute
    include NotA_C_Pointer

    default = 'Qnil'

    def declare
      "VALUE #{name};"
    end
  end

  class Attribute::NArray < Attribute::Value
    include NotA_C_Pointer

    default = 'Qnil'
  end
end
