# frozen_string_literal: true

module Crow
  class TypeMap
    # Describes a C `int*` data type.
    class PointerInt < TypeMap
      include IsACPointer

      self.default = 'NULL'
      self.item_default = '0'

      # @return [String] C base type
      def cbase
        'int'
      end

      # @return [String] Ruby type name emitted in generated documentation
      def rdoc_type
        'Array<Integer>'
      end

      # @return [String] C function used to convert an array element to Ruby
      def array_item_to_ruby_converter
        'INT2NUM'
      end

      # @return [Boolean] always false because raw pointers are not serializable
      def self.store_default?
        false
      end
    end

    # Describes a C `unsigned int*` data type.
    class PointerUInt < TypeMap
      include IsACPointer

      self.default = 'NULL'
      self.item_default = '0'

      # @return [String] C base type
      def cbase
        'unsigned int'
      end

      # @return [String] Ruby type name emitted in generated documentation
      def rdoc_type
        'Array<Integer>'
      end

      # @return [String] C function used to convert an array element to Ruby
      def array_item_to_ruby_converter
        'UINT2NUM'
      end

      # @return [Boolean] always false because raw pointers are not serializable
      def self.store_default?
        false
      end
    end

    # Describes a C `long*` data type.
    class PointerLong < TypeMap
      include IsACPointer

      self.default = 'NULL'
      self.item_default = '0L'

      # @return [String] C base type
      def cbase
        'long'
      end

      # @return [String] Ruby type name emitted in generated documentation
      def rdoc_type
        'Integer'
      end

      # @return [String] C function used to convert an array element to Ruby
      def array_item_to_ruby_converter
        'LONG2NUM'
      end

      # @return [Boolean] always false because raw pointers are not serializable
      def self.store_default?
        false
      end
    end

    # Describes a C `unsigned long*` data type.
    class PointerULong < TypeMap
      include IsACPointer

      self.default = 'NULL'
      self.item_default = '0L'

      # @return [String] C base type
      def cbase
        'unsigned long'
      end

      # @return [String] Ruby type name emitted in generated documentation
      def rdoc_type
        'Array<Integer>'
      end

      # @return [String] C function used to convert an array element to Ruby
      def array_item_to_ruby_converter
        'ULONG2NUM'
      end

      # @return [Boolean] always false because raw pointers are not serializable
      def self.store_default?
        false
      end
    end

    # Describes a C `float*` data type.
    class PointerFloat < TypeMap
      include IsACPointer

      self.default = 'NULL'
      self.item_default = '0.0'

      # @return [String] C base type
      def cbase
        'float'
      end

      # @return [String] Ruby type name emitted in generated documentation
      def rdoc_type
        'Array<Float>'
      end

      # @return [String] C function used to convert an array element to Ruby
      def array_item_to_ruby_converter
        'FLT2NUM'
      end

      # @return [Boolean] always false because raw pointers are not serializable
      def self.store_default?
        false
      end
    end

    # Describes a C `double*` data type.
    class PointerDouble < TypeMap
      include IsACPointer

      self.default = 'NULL'
      self.item_default = '0.0'

      # @return [String] C base type
      def cbase
        'double'
      end

      # @return [String] Ruby type name emitted in generated documentation
      def rdoc_type
        'Array<Float>'
      end

      # @return [String] C function used to convert an array element to Ruby
      def array_item_to_ruby_converter
        'DBL2NUM'
      end

      # @return [Boolean] always false because raw pointers are not serializable
      def self.store_default?
        false
      end
    end

    # Describes a C `char*` data type.
    class PointerChar < TypeMap
      include IsACPointer

      self.default = 'NULL'
      self.item_default = '0'

      # @return [String] C base type
      def cbase
        'char'
      end

      # @return [String] Ruby type name emitted in generated documentation
      def rdoc_type
        'String'
      end

      # @return [Boolean] always false because raw pointers are not serializable
      def self.store_default?
        false
      end
    end
  end
end
