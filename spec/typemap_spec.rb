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
end
