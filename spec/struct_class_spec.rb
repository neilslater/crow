require 'spec_helper'

describe Crow::StructClass do
  let(:libdef) { Crow::LibDef.new('foo') }

  describe 'minimal struct' do
    subject { Crow::StructClass.new('bar', parent_lib: libdef) }

    it 'has default names' do
      expect(subject.short_name).to eql 'bar'
      expect(subject.struct_name).to eql 'Bar'
      expect(subject.rb_class_name).to eql 'Bar'

      expect(subject.lib_short_name).to eql 'foo'
      expect(subject.lib_module_name).to eql 'Foo'
      expect(subject.full_class_name).to eql 'Foo_Bar'
      expect(subject.full_class_name_ruby).to eql 'Foo::Bar'
    end

    it 'has empty attributes array' do
      expect(subject.attributes).to be_empty
    end

    it 'has empty init_params array' do
      expect(subject.init_params).to be_empty
    end

    it 'has no narrays' do
      expect(subject.any_narray?).to be false
      expect(subject.narray_attributes).to be_empty
    end

    it 'has no attributes requiring malloc' do
      expect(subject.any_alloc?).to be false
      expect(subject.alloc_attributes).to be_empty
    end

    it 'has no attributes requiring initialisation' do
      expect(subject.needs_init?).to be false
    end

    it 'has no "simple" attributes' do
      expect(subject.simple_attributes).to be_empty
      expect(subject.simple_attributes_with_init).to be_empty
    end
  end
end
