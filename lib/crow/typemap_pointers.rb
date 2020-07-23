# frozen_string_literal: true

module Crow
  class TypeMap
    # Describes a C `int*` data type.
    class PointerInt < TypeMap
      include IsACPointer
      self.default = 'NULL'
      self.item_default = '0'

      def cbase
        'int'
      end

      def rdoc_type
        'Array<Integer>'
      end

      def array_item_to_ruby_converter
        'INT2NUM'
      end

      def self.store_default
        false
      end
    end

    # Describes a C `unsigned int*` data type.
    class PointerUInt < TypeMap
      include IsACPointer
      self.default = 'NULL'
      self.item_default = '0'

      def cbase
        'unsigned int'
      end

      def rdoc_type
        'Array<Integer>'
      end

      def array_item_to_ruby_converter
        'UINT2NUM'
      end

      def self.store_default
        false
      end
    end

    # Describes a C `long*` data type.
    class PointerLong < TypeMap
      include IsACPointer
      self.default = 'NULL'
      self.item_default = '0L'

      def cbase
        'long'
      end

      def rdoc_type
        'Integer'
      end

      def array_item_to_ruby_converter
        'LONG2NUM'
      end

      def self.store_default
        false
      end
    end

    # Describes a C `unsigned long*` data type.
    class PointerULong < TypeMap
      include IsACPointer
      self.default = 'NULL'
      self.item_default = '0L'

      def cbase
        'unsigned long'
      end

      def rdoc_type
        'Array<Integer>'
      end

      def array_item_to_ruby_converter
        'ULONG2NUM'
      end

      def self.store_default
        false
      end
    end

    # Describes a C `float*` data type.
    class PointerFloat < TypeMap
      include IsACPointer
      self.default = 'NULL'
      self.item_default = '0.0'

      def cbase
        'float'
      end

      def rdoc_type
        'Array<Float>'
      end

      def array_item_to_ruby_converter
        'FLT2NUM'
      end

      def self.store_default
        false
      end
    end

    # Describes a C `double*` data type.
    class PointerDouble < TypeMap
      include IsACPointer
      self.default = 'NULL'
      self.item_default = '0.0'

      def cbase
        'double'
      end

      def rdoc_type
        'Array<Float>'
      end

      def array_item_to_ruby_converter
        'DBL2NUM'
      end

      def self.store_default
        false
      end
    end

    # Describes a C `char*` data type.
    class PointerChar < TypeMap
      include IsACPointer
      self.default = 'NULL'
      self.item_default = '0'

      def cbase
        'char'
      end

      def rdoc_type
        'String'
      end

      def self.store_default
        false
      end
    end
  end
end
