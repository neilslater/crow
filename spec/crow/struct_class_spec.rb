# frozen_string_literal: true

require 'spec_helper'

describe Crow::StructClass do
  let(:libdef) { Crow::LibDef.new('foo') }

  it 'rejects a short name that is not a C identifier component' do
    expect { described_class.new('not-valid') }.to raise_error RuntimeError, /cannot be used/
  end

  def write_files(paths, contents)
    paths.each { |path| File.write(path, contents) }
  end

  def create_user_files(dir, expected_name)
    FileUtils.mkdir_p File.join(dir, 'ruby')
    paths = %w[h c].map { |extension| File.join(dir, 'ruby', "class_#{expected_name}.#{extension}") }
    write_files(paths, "Leave me alone!\n")
    paths
  end

  def expected_base_files(dir, expected_name)
    %W[
      #{dir}/base/struct_#{expected_name}.h
      #{dir}/base/struct_#{expected_name}.c
      #{dir}/base/ruby_class_#{expected_name}.h
      #{dir}/base/ruby_class_#{expected_name}.c
    ]
  end

  shared_examples 'a C source creator' do |expected_name|
    describe '#write' do
      it 'creates four suitably-named "base" files' do
        Dir.mktmpdir do |dir|
          struct_class.write(dir)
          expect(expected_base_files(dir, expected_name)).to all_exist
        end
      end
    end

    describe '#write_user' do
      it 'creates two suitably-named "ruby" files' do
        Dir.mktmpdir do |dir|
          struct_class.write_user(dir)
          expect(%W[#{dir}/ruby/class_#{expected_name}.h #{dir}/ruby/class_#{expected_name}.c]).to all_exist
        end
      end

      it 'does not over-write existing "ruby" files' do
        Dir.mktmpdir do |dir|
          target_files = create_user_files(dir, expected_name)
          struct_class.write_user(dir)
          expect(target_files.map { |path| File.read(path) }).to all eq "Leave me alone!\n"
        end
      end
    end
  end

  describe 'minimal struct' do
    subject(:struct_class) { described_class.new('bar', parent_lib: libdef) }

    it 'has default names' do
      expect(struct_class).to have_attributes(
        short_name: 'bar',
        struct_name: 'Bar',
        rb_class_name: 'Bar',
        lib_short_name: 'foo',
        lib_module_name: 'Foo',
        full_class_name: 'Foo_Bar',
        full_class_name_ruby: 'Foo::Bar'
      )
    end

    it 'has empty attributes array' do
      expect(struct_class.attributes).to be_empty
    end

    it 'has empty init_params array' do
      expect(struct_class.init_params).to be_empty
    end

    it 'has no narrays' do
      expect(struct_class).to have_attributes(any_narray?: false, narray_attributes: be_empty)
    end

    it 'has no attributes requiring malloc' do
      expect(struct_class).to have_attributes(any_alloc?: false, alloc_attributes: be_empty)
    end

    it 'has no attributes requiring initialisation' do
      expect(struct_class.needs_init?).to be false
    end

    it 'has no "simple" attributes' do
      expect(struct_class).to have_attributes(simple_attributes: be_empty, simple_attributes_with_init: be_empty)
    end

    it_behaves_like 'a C source creator', 'bar'
  end

  describe 'stored attributes' do
    subject(:struct_class) do
      described_class.new('bar',
                          parent_lib: libdef,
                          attributes: [{ name: 'saved', ctype: :int },
                                       { name: 'transient', ctype: :int, store: false }])
    end

    it 'separates stored and non-stored attributes' do
      groups = [struct_class.stored_attributes, struct_class.non_stored_attributes]
      expect(groups.map { |attributes| attributes.map(&:name) }).to eq [%w[saved], %w[transient]]
    end
  end
end
