# frozen_string_literal: true

module Crow
  class TypeMap::Int < TypeMap
    include NotACPointer
    self.default = '0'

    def cbase
      'int'
    end

    def rdoc_type
      'Integer'
    end

    def self.ruby_to_c(ruby_name)
      "NUM2INT( #{ruby_name} )"
    end

    def self.c_to_ruby(c_name)
      "INT2NUM( #{c_name} )"
    end
  end

  class TypeMap::UInt < TypeMap::Int
    include NotACPointer

    self.default = '0'

    def cbase
      'unsigned int'
    end

    def rdoc_type
      'Integer'
    end

    def self.ruby_to_c(ruby_name)
      "NUM2UINT( #{ruby_name} )"
    end

    def self.c_to_ruby(c_name)
      "UINT2NUM( #{c_name} )"
    end
  end

  class TypeMap::Long < TypeMap
    include NotACPointer

    self.default = '0L'

    def cbase
      'long'
    end

    def rdoc_type
      'Integer'
    end

    def self.ruby_to_c(ruby_name)
      "NUM2LONG( #{ruby_name} )"
    end

    def self.c_to_ruby(c_name)
      "LONG2NUM( #{c_name} )"
    end
  end

  class TypeMap::ULong < TypeMap::Long
    include NotACPointer
    self.default = '0L'

    def cbase
      'unsigned long'
    end

    def rdoc_type
      'Integer'
    end

    def self.ruby_to_c(ruby_name)
      "NUM2ULONG( #{ruby_name} )"
    end

    def self.c_to_ruby(c_name)
      "ULONG2NUM( #{c_name} )"
    end
  end

  class TypeMap::Float < TypeMap
    include NotACPointer
    self.default = '0.0'

    def cbase
      'float'
    end

    def rdoc_type
      'Float'
    end

    def self.ruby_to_c(ruby_name)
      "NUM2FLT( #{ruby_name} )"
    end

    def self.c_to_ruby(c_name)
      "FLT2NUM( #{c_name} )"
    end
  end

  class TypeMap::Double < TypeMap
    include NotACPointer
    self.default = '0.0'

    def cbase
      'double'
    end

    def rdoc_type
      'Float'
    end

    def self.ruby_to_c(ruby_name)
      "NUM2DBL( #{ruby_name} )"
    end

    def self.c_to_ruby(c_name)
      "DBL2NUM( #{c_name} )"
    end
  end

  class TypeMap::Char < TypeMap
    include NotACPointer
    self.default = '0'

    def cbase
      'char'
    end

    def rdoc_type
      'Byte'
    end

    def self.ruby_to_c(ruby_name)
      "NUM2CHR( #{ruby_name} )"
    end

    def self.c_to_ruby(c_name)
      "LONG2FIX( #{c_name} )"
    end
  end

  class TypeMap::Value < TypeMap
    include NotACPointer
    self.default = 'Qnil'

    def cbase
      'volatile VALUE'
    end

    def needs_gc_mark?
      true
    end

    def cast
      'ERROR'
    end

    def rdoc_type
      'Object'
    end

    def self.ruby_to_c(ruby_name)
      ruby_name
    end

    def self.c_to_ruby(c_name)
      c_name
    end
  end
end
