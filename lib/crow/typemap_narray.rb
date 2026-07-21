# frozen_string_literal: true

module Crow
  class TypeMap
    # Describes a C `VALUE` data type intended to be used with a Numo::NArray.
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
        'Numo::NArray'
      end

      def declare_ptr_cache
        "#{item_ctype} *#{ptr_tmp_var};"
      end

      def declare_shape_var
        "size_t *#{shape_tmp_var};"
      end

      def set_ptr_cache
        "#{ptr_tmp_var} = (#{item_ctype} *)na_get_pointer_for_write( " \
          "#{@parent_struct.short_name}->#{name} );"
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

    # Describes a C `VALUE` data type intended to be used with a Numo::SFloat.
    class NArrayFloat < TypeMap::NArray
      include NotACPointer

      self.default = 'Qnil'
      self.item_default = '0.0'

      def item_ctype
        'float'
      end

      def narray_enum_type
        'numo_cSFloat'
      end

      def rdoc_type
        'Numo::SFloat'
      end
    end

    # Describes a C `VALUE` data type intended to be used with a Numo::DFloat.
    class NArrayDouble < TypeMap::NArray
      include NotACPointer

      self.default = 'Qnil'
      self.item_default = '0.0'

      def item_ctype
        'double'
      end

      def narray_enum_type
        'numo_cDFloat'
      end

      def rdoc_type
        'Numo::DFloat'
      end
    end

    # Describes a C `VALUE` data type intended to be used with a Numo::Int16.
    class NArraySInt < TypeMap::NArray
      include NotACPointer

      self.default = 'Qnil'
      self.item_default = '0'

      def item_ctype
        'int16_t'
      end

      def narray_enum_type
        'numo_cInt16'
      end

      def rdoc_type
        'Numo::Int16'
      end
    end

    # Describes a C `VALUE` data type intended to be used with a Numo::Int32.
    class NArrayLInt < TypeMap::NArray
      include NotACPointer

      self.default = 'Qnil'
      self.item_default = '0'

      def item_ctype
        'int32_t'
      end

      def narray_enum_type
        'numo_cInt32'
      end

      def rdoc_type
        'Numo::Int32'
      end
    end
  end
end
