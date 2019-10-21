require 'spec_helper'

describe Crow::TypeMap do
  let(:container) { Crow::StructClass.new('foo') }

  describe 'create' do
    it 'does not create a TypeMap without a ctype' do
      expect {
        Crow::TypeMap.create('x', parent_struct: container)
      }.to raise_error ArgumentError, /Type '' not supported\./
    end

    it 'does not create a TypeMap with a bad ctype' do
      expect {
        Crow::TypeMap.create('x', ctype: 'fish', parent_struct: container)
      }.to raise_error ArgumentError, /Type 'fish' not supported\./
    end

    it 'does not create a TypeMap without a parent_struct' do
      expect {
        Crow::TypeMap.create('x', ctype: :int)
      }.to raise_error ArgumentError, /missing keyword: parent_struct/
    end

    it 'does not create a TypeMap with a bad parent_struct' do
      expect {
        Crow::TypeMap.create('x', ctype: :int, parent_struct: 'Foo')
      }.to raise_error ArgumentError, 'parent_struct must be a Crow::StructClass'
    end

    it 'creates a Ruby read-only attribute by default' do
      typemap = Crow::TypeMap.create('x', ctype: :int, parent_struct: container)
      expect(typemap.read_only?).to be true
      expect(typemap.ruby_read).to be true
      expect(typemap.ruby_write).to be false
    end

    it 'can create a Ruby read-write attribute' do
      typemap = Crow::TypeMap.create('x', ctype: :int, parent_struct: container, ruby_write: true)
      expect(typemap.read_only?).to be false
      expect(typemap.ruby_read).to be true
      expect(typemap.ruby_write).to be true
    end

    it 'can create an internal-only attribute' do
      typemap = Crow::TypeMap.create('x', ctype: :int, parent_struct: container, ruby_read: false)
      expect(typemap.read_only?).to be false
      expect(typemap.ruby_read).to be false
      expect(typemap.ruby_write).to be false
    end

    it 'has naming conventions for templating' do
      typemap = Crow::TypeMap.create('x', ctype: :int, parent_struct: container)
      expect(typemap.name).to eql 'x'
      expect(typemap.rv_name).to eql 'rv_x'
      expect(typemap.as_rv_param).to eql 'VALUE rv_x'
      expect(typemap.struct_item).to eql 'foo->x'
    end

    context 'initialisation' do
      it 'can accept arbitrary initialisation' do
        typemap = Crow::TypeMap.create('x', ctype: :int, parent_struct: container, init: { expr: 'frobnicate()' })
        expect(typemap.init_expr_c).to eql 'frobnicate()'
      end

      it 'can refer other parameters from the same struct using %' do
        container.add_attribute( 'y', ctype: :int )
        typemap = Crow::TypeMap.create('x', ctype: :int, parent_struct: container, init: { expr: '%y' })
        expect(typemap.init_expr_c).to eql 'foo->y'
      end

      it 'can refer other parameters from a renamed struct using % and optional container name' do
        container.add_attribute( 'y', ctype: :int )
        typemap = Crow::TypeMap.create('x', ctype: :int, parent_struct: container, init: { expr: '%y' })
        expect(typemap.init_expr_c(from: 'alt_foo')).to eql 'alt_foo->y'
      end

      it 'can accept self-referential init param "."' do
        container.add_attribute( 'y', ctype: :int )
        container.init_params << Crow::TypeMap.create( 'y', ctype: :int, parent_struct: container )
        typemap = Crow::TypeMap.create('y', ctype: :int, parent_struct: container, init: { expr: '.' })
        expect(typemap.init_expr_c(init_context: true)).to eql 'y'
      end

      it 'can accept self-referential init param "." in container context' do
        container.add_attribute( 'y', ctype: :int )
        typemap = Crow::TypeMap.create('y', ctype: :int, parent_struct: container, init: { expr: '.' })
        expect(typemap.init_expr_c(from: 'alt_foo')).to eql 'alt_foo->y'
      end
    end
  end

  describe Crow::TypeMap::Int do
    subject { Crow::TypeMap.create('x', ctype: :int, parent_struct: container) }

    it 'has correct template declare' do
      expect(subject.declare).to eql 'int x;'
    end

    it 'has correct template as_param' do
      expect(subject.as_param).to eql 'int x'
    end

    it 'has correct template cast' do
      expect(subject.cast).to eql '(int)'
    end

    it 'is not a NArray' do
      expect(subject.is_narray?).to be false
    end

    it 'has correct to Ruby converter for template' do
      expect(subject.struct_item_to_ruby).to eql 'INT2NUM( foo->x )'
    end

    it 'has correct from Ruby converter for template' do
      expect(subject.param_item_to_c).to eql 'NUM2INT( rv_x )'
    end
  end


  describe Crow::TypeMap::P_Int do
    subject { Crow::TypeMap.create('x', ctype: :int, pointer: true, parent_struct: container) }

    it 'has correct template declare' do
      expect(subject.declare).to eql 'int *x;'
    end

    it 'has correct template as_param' do
      expect(subject.as_param).to eql 'int *x'
    end

    it 'has correct template cast' do
      expect(subject.cast).to eql '(int*)'
    end

    it 'is not a NArray' do
      expect(subject.is_narray?).to be false
    end

    # No Ruby/C converters for arrays yet . . .
  end

  describe Crow::TypeMap::Float do
    subject { Crow::TypeMap.create('x', ctype: :float, parent_struct: container) }

    it 'has correct template declare' do
      expect(subject.declare).to eql 'float x;'
    end

    it 'has correct template as_param' do
      expect(subject.as_param).to eql 'float x'
    end

    it 'has correct template cast' do
      expect(subject.cast).to eql '(float)'
    end

    it 'is not a NArray' do
      expect(subject.is_narray?).to be false
    end

    it 'has correct to Ruby converter for template' do
      expect(subject.struct_item_to_ruby).to eql 'FLT2NUM( foo->x )'
    end

    it 'has correct from Ruby converter for template' do
      expect(subject.param_item_to_c).to eql 'NUM2FLT( rv_x )'
    end
  end

  describe Crow::TypeMap::P_Float do
    subject { Crow::TypeMap.create('x', ctype: :float, pointer: true, parent_struct: container) }

    it 'has correct template declare' do
      expect(subject.declare).to eql 'float *x;'
    end

    it 'has correct template as_param' do
      expect(subject.as_param).to eql 'float *x'
    end

    it 'has correct template cast' do
      expect(subject.cast).to eql '(float*)'
    end

    it 'is not a NArray' do
      expect(subject.is_narray?).to be false
    end

    # No Ruby/C converters for arrays yet . . .
  end

  describe Crow::TypeMap::Double do
    subject { Crow::TypeMap.create('x', ctype: :double, parent_struct: container) }

    it 'has correct template declare' do
      expect(subject.declare).to eql 'double x;'
    end

    it 'has correct template as_param' do
      expect(subject.as_param).to eql 'double x'
    end

    it 'has correct template cast' do
      expect(subject.cast).to eql '(double)'
    end

    it 'is not a NArray' do
      expect(subject.is_narray?).to be false
    end

    it 'has correct to Ruby converter for template' do
      expect(subject.struct_item_to_ruby).to eql 'DBL2NUM( foo->x )'
    end

    it 'has correct from Ruby converter for template' do
      expect(subject.param_item_to_c).to eql 'NUM2DBL( rv_x )'
    end
  end

  describe Crow::TypeMap::P_Double do
    subject { Crow::TypeMap.create('x', ctype: :double, pointer: true, parent_struct: container) }

    it 'has correct template declare' do
      expect(subject.declare).to eql 'double *x;'
    end

    it 'has correct template as_param' do
      expect(subject.as_param).to eql 'double *x'
    end

    it 'has correct template cast' do
      expect(subject.cast).to eql '(double*)'
    end

    it 'is not a NArray' do
      expect(subject.is_narray?).to be false
    end

    # No Ruby/C converters for arrays yet . . .
  end

  describe Crow::TypeMap::Char do
    subject { Crow::TypeMap.create('x', ctype: :char, parent_struct: container) }

    it 'has correct template declare' do
      expect(subject.declare).to eql 'char x;'
    end

    it 'has correct template as_param' do
      expect(subject.as_param).to eql 'char x'
    end

    it 'has correct template cast' do
      expect(subject.cast).to eql '(char)'
    end

    it 'is not a NArray' do
      expect(subject.is_narray?).to be false
    end

    it 'has correct to Ruby converter for template' do
      expect(subject.struct_item_to_ruby).to eql 'LONG2FIX( foo->x )'
    end

    it 'has correct from Ruby converter for template' do
      expect(subject.param_item_to_c).to eql 'NUM2CHR( rv_x )'
    end
  end

  describe Crow::TypeMap::P_Char do
    subject { Crow::TypeMap.create('x', ctype: :char, pointer: true, parent_struct: container) }

    it 'has correct template declare' do
      expect(subject.declare).to eql 'char *x;'
    end

    it 'has correct template as_param' do
      expect(subject.as_param).to eql 'char *x'
    end

    it 'has correct template cast' do
      expect(subject.cast).to eql '(char*)'
    end

    it 'is not a NArray' do
      expect(subject.is_narray?).to be false
    end

    # No Ruby/C converters for arrays yet . . .
  end


  describe Crow::TypeMap::Long do
    subject { Crow::TypeMap.create('x', ctype: :long, parent_struct: container) }

    it 'has correct template declare' do
      expect(subject.declare).to eql 'long x;'
    end

    it 'has correct template as_param' do
      expect(subject.as_param).to eql 'long x'
    end

    it 'has correct template cast' do
      expect(subject.cast).to eql '(long)'
    end

    it 'is not a NArray' do
      expect(subject.is_narray?).to be false
    end

    it 'has correct to Ruby converter for template' do
      expect(subject.struct_item_to_ruby).to eql 'LONG2NUM( foo->x )'
    end

    it 'has correct from Ruby converter for template' do
      expect(subject.param_item_to_c).to eql 'NUM2LONG( rv_x )'
    end
  end

  describe Crow::TypeMap::P_Long do
    subject { Crow::TypeMap.create('x', ctype: :long, pointer: true, parent_struct: container) }

    it 'has correct template declare' do
      expect(subject.declare).to eql 'long *x;'
    end

    it 'has correct template as_param' do
      expect(subject.as_param).to eql 'long *x'
    end

    it 'has correct template cast' do
      expect(subject.cast).to eql '(long*)'
    end

    it 'is not a NArray' do
      expect(subject.is_narray?).to be false
    end

    # No Ruby/C converters for arrays yet . . .
  end


  describe Crow::TypeMap::UInt do
    subject { Crow::TypeMap.create('x', ctype: :uint, parent_struct: container) }

    it 'has correct template declare' do
      expect(subject.declare).to eql 'unsigned int x;'
    end

    it 'has correct template as_param' do
      expect(subject.as_param).to eql 'unsigned int x'
    end

    it 'has correct template cast' do
      expect(subject.cast).to eql '(unsigned int)'
    end

    it 'is not a NArray' do
      expect(subject.is_narray?).to be false
    end

    it 'has correct to Ruby converter for template' do
      expect(subject.struct_item_to_ruby).to eql 'UINT2NUM( foo->x )'
    end

    it 'has correct from Ruby converter for template' do
      expect(subject.param_item_to_c).to eql 'NUM2UINT( rv_x )'
    end
  end

  describe Crow::TypeMap::P_UInt do
    subject { Crow::TypeMap.create('x', ctype: :uint, pointer: true, parent_struct: container) }

    it 'has correct template declare' do
      expect(subject.declare).to eql 'unsigned int *x;'
    end

    it 'has correct template as_param' do
      expect(subject.as_param).to eql 'unsigned int *x'
    end

    it 'has correct template cast' do
      expect(subject.cast).to eql '(unsigned int*)'
    end

    it 'is not a NArray' do
      expect(subject.is_narray?).to be false
    end

    # No Ruby/C converters for arrays yet . . .
  end



  describe Crow::TypeMap::ULong do
    subject { Crow::TypeMap.create('x', ctype: :ulong, parent_struct: container) }

    it 'has correct template declare' do
      expect(subject.declare).to eql 'unsigned long x;'
    end

    it 'has correct template as_param' do
      expect(subject.as_param).to eql 'unsigned long x'
    end

    it 'has correct template cast' do
      expect(subject.cast).to eql '(unsigned long)'
    end

    it 'is not a NArray' do
      expect(subject.is_narray?).to be false
    end

    it 'has correct to Ruby converter for template' do
      expect(subject.struct_item_to_ruby).to eql 'ULONG2NUM( foo->x )'
    end

    it 'has correct from Ruby converter for template' do
      expect(subject.param_item_to_c).to eql 'NUM2ULONG( rv_x )'
    end
  end

  describe Crow::TypeMap::P_ULong do
    subject { Crow::TypeMap.create('x', ctype: :ulong, pointer: true, parent_struct: container) }

    it 'has correct template declare' do
      expect(subject.declare).to eql 'unsigned long *x;'
    end

    it 'has correct template as_param' do
      expect(subject.as_param).to eql 'unsigned long *x'
    end

    it 'has correct template cast' do
      expect(subject.cast).to eql '(unsigned long*)'
    end

    it 'is not a NArray' do
      expect(subject.is_narray?).to be false
    end

    # No Ruby/C converters for arrays yet . . .
  end


  describe Crow::TypeMap::Value do
    subject { Crow::TypeMap.create('x', ctype: :VALUE, parent_struct: container) }

    it 'has correct template declare' do
      expect(subject.declare).to eql 'volatile VALUE x;'
    end

    it 'has correct template as_param' do
      # TODO: Is this correct?
      expect(subject.as_param).to eql 'volatile VALUE x'
    end

    it 'has correct template cast' do
      expect(subject.cast).to eql 'ERROR'
    end

    it 'is not a NArray' do
      expect(subject.is_narray?).to be false
    end

    it 'has correct to Ruby converter for template' do
      expect(subject.struct_item_to_ruby).to eql 'foo->x'
    end

    it 'has correct from Ruby converter for template' do
      # TODO: There should be a validation that we have a T_OBJECT here?
      expect(subject.param_item_to_c).to eql 'rv_x'
    end
  end


  describe Crow::TypeMap::NArrayFloat do
    subject { Crow::TypeMap.create('x', ctype: :NARRAY_FLOAT, parent_struct: container) }

    it 'has correct template declare' do
      expect(subject.declare).to eql 'volatile VALUE x;'
    end

    it 'has correct template as_param' do
      # TODO: Is this correct?
      expect(subject.as_param).to eql 'volatile VALUE x'
    end

    it 'has correct template cast' do
      expect(subject.cast).to eql 'ERROR'
    end

    it 'is a NArray' do
      expect(subject.is_narray?).to be true
    end

    it 'has correct to Ruby converter for template' do
      expect(subject.struct_item_to_ruby).to eql 'foo->x'
    end

    it 'has correct from Ruby converter for template' do
      # TODO: There should be a validation that we have a NArray here, and casting from existing type
      expect(subject.param_item_to_c).to eql 'rv_x'
    end

    it 'overrides item_ctype' do
      expect(subject.item_ctype).to eql 'float'
    end

    it 'overrides narray_enum_type' do
      expect(subject.narray_enum_type).to eql 'NA_SFLOAT'
    end

    it 'overrides rdoc_type' do
      expect(subject.rdoc_type).to eql 'NArray<sfloat>'
    end
  end


  describe Crow::TypeMap::NArrayDouble do
    subject { Crow::TypeMap.create('x', ctype: :NARRAY_DOUBLE, parent_struct: container) }

    it 'has correct template declare' do
      expect(subject.declare).to eql 'volatile VALUE x;'
    end

    it 'has correct template as_param' do
      # TODO: Is this correct?
      expect(subject.as_param).to eql 'volatile VALUE x'
    end

    it 'has correct template cast' do
      expect(subject.cast).to eql 'ERROR'
    end

    it 'is a NArray' do
      expect(subject.is_narray?).to be true
    end

    it 'has correct to Ruby converter for template' do
      expect(subject.struct_item_to_ruby).to eql 'foo->x'
    end

    it 'has correct from Ruby converter for template' do
      # TODO: There should be a validation that we have a NArray here, and casting from existing type
      expect(subject.param_item_to_c).to eql 'rv_x'
    end

    it 'overrides item_ctype' do
      expect(subject.item_ctype).to eql 'double'
    end

    it 'overrides narray_enum_type' do
      expect(subject.narray_enum_type).to eql 'NA_DFLOAT'
    end

    it 'overrides rdoc_type' do
      expect(subject.rdoc_type).to eql 'NArray<float>'
    end
  end


  describe Crow::TypeMap::NArraySInt do
    subject { Crow::TypeMap.create('x', ctype: :NARRAY_INT_16, parent_struct: container) }

    it 'has correct template declare' do
      expect(subject.declare).to eql 'volatile VALUE x;'
    end

    it 'has correct template as_param' do
      # TODO: Is this correct?
      expect(subject.as_param).to eql 'volatile VALUE x'
    end

    it 'has correct template cast' do
      expect(subject.cast).to eql 'ERROR'
    end

    it 'is a NArray' do
      expect(subject.is_narray?).to be true
    end

    it 'has correct to Ruby converter for template' do
      expect(subject.struct_item_to_ruby).to eql 'foo->x'
    end

    it 'has correct from Ruby converter for template' do
      # TODO: There should be a validation that we have a NArray here, and casting from existing type
      expect(subject.param_item_to_c).to eql 'rv_x'
    end

    it 'overrides item_ctype' do
      expect(subject.item_ctype).to eql 'int16_t'
    end

    it 'overrides narray_enum_type' do
      expect(subject.narray_enum_type).to eql 'NA_SINT'
    end

    it 'overrides rdoc_type' do
      expect(subject.rdoc_type).to eql 'NArray<sint>'
    end
  end

  describe Crow::TypeMap::NArrayLInt do
    subject { Crow::TypeMap.create('x', ctype: :NARRAY_INT_32, parent_struct: container) }

    it 'has correct template declare' do
      expect(subject.declare).to eql 'volatile VALUE x;'
    end

    it 'has correct template as_param' do
      # TODO: Is this correct?
      expect(subject.as_param).to eql 'volatile VALUE x'
    end

    it 'has correct template cast' do
      expect(subject.cast).to eql 'ERROR'
    end

    it 'is a NArray' do
      expect(subject.is_narray?).to be true
    end

    it 'has correct to Ruby converter for template' do
      expect(subject.struct_item_to_ruby).to eql 'foo->x'
    end

    it 'has correct from Ruby converter for template' do
      # TODO: There should be a validation that we have a NArray here, and casting from existing type
      expect(subject.param_item_to_c).to eql 'rv_x'
    end

    it 'overrides item_ctype' do
      expect(subject.item_ctype).to eql 'int32_t'
    end

    it 'overrides narray_enum_type' do
      expect(subject.narray_enum_type).to eql 'NA_LINT'
    end

    it 'overrides rdoc_type' do
      expect(subject.rdoc_type).to eql 'NArray<int>'
    end
  end
end
