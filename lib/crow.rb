require "crow/version"
require 'erb'

module Crow
  class StructClass
    attr_accessor :short_name, :struct_name, :attributes

    TEMPLATE_DIR = File.realdirpath( File.join( __dir__, '../lib/templates' ) )
    TEMPLATES = [ 'struct_dataset.h', 'struct_dataset.c', 'ruby_class_dataset.h', 'ruby_class_dataset.c' ]

    def initialize( short_name, opts = {} )
      raise "Short name '#{short_name}' cannot be used" if short_name !~ /\A[a-zA-Z0-9_]+\z/
      @short_name = short_name
      @struct_name = opts[:struct_name] || struct_name_from_short_name( @short_name )
      if opts[:attributes]
        @attributes = opts[:attributes].map do | attr_opts |
          attr_name = attr_opts[:name]
          Attribute.create( attr_name, attr_opts )
        end
      else
        @attributes = []
      end
    end

    def write path
      TEMPLATES.each do |template|
        File.open( File.join( path, template.sub( /dataset/, short_name ) ), 'w' ) do |file|
          file.puts render( File.join( TEMPLATE_DIR, template ) )
        end
      end
    end

    def add_attribute name, opts = {}
      @attributes << Attribute.create( name, opts )
    end

    def any_narray?
      @attributes.any? { |a| [:NARRAY].include?( a.ctype ) }
    end

    def any_alloc?
      @attributes.any? { |a| a.needs_alloc? }
    end

    private

    def render template_file
      erb = ERB.new( File.read( template_file ), 0, '-' )
      erb.result( binding )
    end

    def struct_name_from_short_name sname
      parts = sname.split('_')
      parts.map { |part| part[0].upcase + part[1,30] }.join
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

      self.const_get( attribute_class ).new( name, opts )
    end

    def self.default
      @class_default
    end

    def self.default= new_default
      @class_default = new_default
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
    self.default = '0'

    def cbase
      "int"
    end
  end

  class Attribute::P_Int < Attribute
    include IsA_C_Pointer
    self.default = 'NULL'

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
  end
end
