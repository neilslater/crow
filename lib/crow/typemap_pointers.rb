# frozen_string_literal: true

module Crow
  class TypeMap::P_Int < TypeMap
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

  class TypeMap::P_UInt < TypeMap
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

  class TypeMap::P_Long < TypeMap
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

  class TypeMap::P_ULong < TypeMap
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

  class TypeMap::P_Float < TypeMap
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

  class TypeMap::P_Double < TypeMap
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

  class TypeMap::P_Char < TypeMap
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
