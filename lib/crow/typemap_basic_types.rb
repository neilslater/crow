# frozen_string_literal: true

module Crow
  class TypeMap
    # Describes a C `int` data type.
    class Int < TypeMap
      include NotACPointer

      self.default = '0'

      # @return [String] C base type
      def cbase
        'int'
      end

      # @return [String] Ruby type name emitted in generated documentation
      def rdoc_type
        'Integer'
      end

      # @param [String] ruby_name C expression containing a Ruby VALUE
      # @return [String] C conversion expression
      def self.ruby_to_c(ruby_name)
        "NUM2INT( #{ruby_name} )"
      end

      # @param [String] c_name C value expression
      # @return [String] Ruby conversion expression
      def self.c_to_ruby(c_name)
        "INT2NUM( #{c_name} )"
      end
    end

    # Describes a C `unsigned int` data type.
    class UInt < TypeMap
      include NotACPointer

      self.default = '0'

      # @return [String] C base type
      def cbase
        'unsigned int'
      end

      # @return [String] Ruby type name emitted in generated documentation
      def rdoc_type
        'Integer'
      end

      # @param [String] ruby_name C expression containing a Ruby VALUE
      # @return [String] C conversion expression
      def self.ruby_to_c(ruby_name)
        "NUM2UINT( #{ruby_name} )"
      end

      # @param [String] c_name C value expression
      # @return [String] Ruby conversion expression
      def self.c_to_ruby(c_name)
        "UINT2NUM( #{c_name} )"
      end
    end

    # Describes a C `long` data type.
    class Long < TypeMap
      include NotACPointer

      self.default = '0L'

      # @return [String] C base type
      def cbase
        'long'
      end

      # @return [String] Ruby type name emitted in generated documentation
      def rdoc_type
        'Integer'
      end

      # @param [String] ruby_name C expression containing a Ruby VALUE
      # @return [String] C conversion expression
      def self.ruby_to_c(ruby_name)
        "NUM2LONG( #{ruby_name} )"
      end

      # @param [String] c_name C value expression
      # @return [String] Ruby conversion expression
      def self.c_to_ruby(c_name)
        "LONG2NUM( #{c_name} )"
      end
    end

    # Describes a C `unsigned long` data type.
    class ULong < TypeMap::Long
      include NotACPointer

      self.default = '0L'

      # @return [String] C base type
      def cbase
        'unsigned long'
      end

      # @return [String] Ruby type name emitted in generated documentation
      def rdoc_type
        'Integer'
      end

      # @param [String] ruby_name C expression containing a Ruby VALUE
      # @return [String] C conversion expression
      def self.ruby_to_c(ruby_name)
        "NUM2ULONG( #{ruby_name} )"
      end

      # @param [String] c_name C value expression
      # @return [String] Ruby conversion expression
      def self.c_to_ruby(c_name)
        "ULONG2NUM( #{c_name} )"
      end
    end

    # Describes a C `float` data type.
    class Float < TypeMap
      include NotACPointer

      self.default = '0.0'

      # @return [String] C base type
      def cbase
        'float'
      end

      # @return [String] Ruby type name emitted in generated documentation
      def rdoc_type
        'Float'
      end

      # @param [String] ruby_name C expression containing a Ruby VALUE
      # @return [String] C conversion expression
      def self.ruby_to_c(ruby_name)
        "NUM2FLT( #{ruby_name} )"
      end

      # @param [String] c_name C value expression
      # @return [String] Ruby conversion expression
      def self.c_to_ruby(c_name)
        "FLT2NUM( #{c_name} )"
      end
    end

    # Describes a C `double` data type.
    class Double < TypeMap
      include NotACPointer

      self.default = '0.0'

      # @return [String] C base type
      def cbase
        'double'
      end

      # @return [String] Ruby type name emitted in generated documentation
      def rdoc_type
        'Float'
      end

      # @param [String] ruby_name C expression containing a Ruby VALUE
      # @return [String] C conversion expression
      def self.ruby_to_c(ruby_name)
        "NUM2DBL( #{ruby_name} )"
      end

      # @param [String] c_name C value expression
      # @return [String] Ruby conversion expression
      def self.c_to_ruby(c_name)
        "DBL2NUM( #{c_name} )"
      end
    end

    # Describes a C `char` data type.
    class Char < TypeMap
      include NotACPointer

      self.default = '0'

      # @return [String] C base type
      def cbase
        'char'
      end

      # @return [String] Ruby type name emitted in generated documentation
      def rdoc_type
        'Byte'
      end

      # @param [String] ruby_name C expression containing a Ruby VALUE
      # @return [String] C conversion expression
      def self.ruby_to_c(ruby_name)
        "NUM2CHR( #{ruby_name} )"
      end

      # @param [String] c_name C value expression
      # @return [String] Ruby conversion expression
      def self.c_to_ruby(c_name)
        "LONG2FIX( #{c_name} )"
      end
    end

    # Describes a C `VALUE` data type from `ruby.h`, i.e. a Ruby Object pointer.
    class Value < TypeMap
      include NotACPointer

      self.default = 'Qnil'

      # @return [String] C base type
      def cbase
        'volatile VALUE'
      end

      # @return [Boolean] always true
      def needs_gc_mark?
        true
      end

      # @return [String] sentinel indicating VALUE casts are invalid
      def cast
        'ERROR'
      end

      # @return [String] Ruby type name emitted in generated documentation
      def rdoc_type
        'Object'
      end

      # @param [String] ruby_name C expression containing a Ruby VALUE
      # @return [String] unchanged VALUE expression
      def self.ruby_to_c(ruby_name)
        ruby_name
      end

      # @param [String] c_name C VALUE expression
      # @return [String] unchanged VALUE expression
      def self.c_to_ruby(c_name)
        c_name
      end
    end
  end
end
