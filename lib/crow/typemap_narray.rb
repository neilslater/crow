# frozen_string_literal: true

module Crow
  class TypeMap
    # Describes a C `VALUE` data type intended to be used with a Numo::NArray.
    class NArray < TypeMap::Value
      include NotACPointer

      self.default = 'Qnil'

      # Name of the temporary C variable holding the NArray shape.
      # @return [String]
      def shape_tmp_var
        @shape_tmp_var ||= "#{@parent_struct.short_name}_#{@name}_shape"
      end

      # Name of the temporary C variable caching the NArray data pointer.
      # @return [String]
      def ptr_tmp_var
        @ptr_tmp_var ||= "#{@parent_struct.short_name}_#{@name}_ptr"
      end

      # Initialization-rule class used for NArray mappings.
      # @return [Class<Crow::TypeInit::NArray>]
      def init_class
        Crow::TypeInit::NArray
      end

      # @return [Boolean] always true
      def narray?
        true
      end

      # Ruby type name emitted in generated documentation.
      # @return [String]
      def rdoc_type
        'Numo::NArray'
      end

      # C declaration for the cached NArray data pointer.
      # @return [String]
      def declare_ptr_cache
        "#{item_ctype} *#{ptr_tmp_var};"
      end

      # C declaration for the cached NArray shape pointer.
      # @return [String]
      def declare_shape_var
        "size_t *#{shape_tmp_var};"
      end

      # C statement that caches the writable NArray data pointer.
      # @return [String]
      def set_ptr_cache
        "#{ptr_tmp_var} = (#{item_ctype} *)na_get_pointer_for_write( " \
          "#{@parent_struct.short_name}->#{name} );"
      end

      # Generated C helper name for retrieving the NArray VALUE.
      # @return [String]
      def narray_fn_name
        "#{@parent_struct.short_name}__get_#{name}_NARRAY"
      end

      # Generated C helper name for retrieving the NArray size.
      # @return [String]
      def size_fn_name
        "#{@parent_struct.short_name}__get_#{name}_size"
      end

      # Generated C helper name for retrieving the NArray rank.
      # @return [String]
      def rank_fn_name
        "#{@parent_struct.short_name}__get_#{name}_rank"
      end

      # Generated C helper name for retrieving the NArray data pointer.
      # @return [String]
      def ptr_fn_name
        "#{@parent_struct.short_name}__get_#{name}_ptr"
      end

      # Generated C helper name for retrieving the NArray shape.
      # @return [String]
      def shape_fn_name
        "#{@parent_struct.short_name}__get_#{name}_shape"
      end
    end

    # Describes a C `VALUE` data type intended to be used with a Numo::SFloat.
    class NArrayFloat < TypeMap::NArray
      include NotACPointer

      self.default = 'Qnil'
      self.item_default = '0.0'

      # @return [String] C element type
      def item_ctype
        'float'
      end

      # @return [String] Numo C API type identifier
      def narray_enum_type
        'numo_cSFloat'
      end

      # @return [String] Ruby type name emitted in generated documentation
      def rdoc_type
        'Numo::SFloat'
      end
    end

    # Describes a C `VALUE` data type intended to be used with a Numo::DFloat.
    class NArrayDouble < TypeMap::NArray
      include NotACPointer

      self.default = 'Qnil'
      self.item_default = '0.0'

      # @return [String] C element type
      def item_ctype
        'double'
      end

      # @return [String] Numo C API type identifier
      def narray_enum_type
        'numo_cDFloat'
      end

      # @return [String] Ruby type name emitted in generated documentation
      def rdoc_type
        'Numo::DFloat'
      end
    end

    # Describes a C `VALUE` data type intended to be used with a Numo::Int16.
    class NArraySInt < TypeMap::NArray
      include NotACPointer

      self.default = 'Qnil'
      self.item_default = '0'

      # @return [String] C element type
      def item_ctype
        'int16_t'
      end

      # @return [String] Numo C API type identifier
      def narray_enum_type
        'numo_cInt16'
      end

      # @return [String] Ruby type name emitted in generated documentation
      def rdoc_type
        'Numo::Int16'
      end
    end

    # Describes a C `VALUE` data type intended to be used with a Numo::Int32.
    class NArrayLInt < TypeMap::NArray
      include NotACPointer

      self.default = 'Qnil'
      self.item_default = '0'

      # @return [String] C element type
      def item_ctype
        'int32_t'
      end

      # @return [String] Numo C API type identifier
      def narray_enum_type
        'numo_cInt32'
      end

      # @return [String] Ruby type name emitted in generated documentation
      def rdoc_type
        'Numo::Int32'
      end
    end
  end
end
