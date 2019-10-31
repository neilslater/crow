module Crow
  class TypeMap::NArray < TypeMap::Value
    include NotA_C_Pointer
    self.default = 'Qnil'

    attr_reader :shape_tmp_var

    def initialize opts = {}
      if ( opts[:shape_var] )
        @shape_var = opts[:shape_var]
      end

      super( opts )

      if ! @shape_var && opts[:init] && ! opts[:init][:shape_expr] && opts[:init][:shape_exprs]
        @shape_tmp_var = @parent_struct.short_name + '_'  + @name + '_shape'
      end

      @ptr_cache = opts[:ptr_cache]
    end

    def init_class
      Crow::TypeInit::NArray
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
