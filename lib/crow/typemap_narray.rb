module Crow
  class TypeMap::NArray < TypeMap::Value
    include NotA_C_Pointer
    self.default = 'Qnil'

    def initialize opts = {}
      super( opts )
    end

    def shape_tmp_var
      @shape_tmp_var ||= @parent_struct.short_name + '_'  + @name + '_shape'
    end

    def ptr_tmp_var
      @ptr_tmp_var ||= @parent_struct.short_name + '_'  + @name + '_ptr'
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
      "#{item_ctype} *#{ptr_tmp_var};"
    end

    def declare_shape_var
      "int *#{shape_tmp_var};"
    end

    def set_ptr_cache
      "#{ptr_tmp_var} = #{ptr_fn_name}( #{@parent_struct.short_name} );"
    end

    def set_shape_var
      "#{shape_tmp_var} = #{shape_fn_name}( #{@parent_struct.short_name} );"
    end

    def narray_fn_name
      "#{@parent_struct.short_name}__get_#{name}_NARRAY"
    end

    def size_fn_name
      "#{@parent_struct.short_name}__get_#{name}_size"
    end

    def rank_fn_name
      "#{@parent_struct.short_name}__get_#{name}_rank"
    end

    def ptr_fn_name
      "#{@parent_struct.short_name}__get_#{name}_ptr"
    end

    def shape_fn_name
      "#{@parent_struct.short_name}__get_#{name}_shape"
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
