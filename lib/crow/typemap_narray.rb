# frozen_string_literal: true

module Crow
  class TypeMap
    # Describes a C `VALUE` data type intended to be used with a NArray.
    class NArray < TypeMap::Value
      include NotACPointer
      self.default = 'Qnil'

      def shape_tmp_var
        @shape_tmp_var ||= "#{@parent_struct.short_name}_#{@name}_shape"
      end

      def ptr_tmp_var
        @ptr_tmp_var ||= "#{@parent_struct.short_name}_#{@name}_ptr"
      end

      def init_class
        Crow::TypeInit::NArray
      end

      def narray?
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

    # Describes a C `VALUE` data type intended to be used with a NArray with NA_SFLOAT subtype.
    class NArrayFloat < TypeMap::NArray
      include NotACPointer
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

    # Describes a C `VALUE` data type intended to be used with a NArray with NA_DFLOAT subtype.
    class NArrayDouble < TypeMap::NArray
      include NotACPointer
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

    # Describes a C `VALUE` data type intended to be used with a NArray with NA_SINT subtype.
    class NArraySInt < TypeMap::NArray
      include NotACPointer
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

    # Describes a C `VALUE` data type intended to be used with a NArray with NA_LINT subtype.
    class NArrayLInt < TypeMap::NArray
      include NotACPointer
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
end
