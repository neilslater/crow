# frozen_string_literal: true

require 'spec_helper'

describe Crow::StructClass do
  let(:libdef) { Crow::LibDef.new('foo') }

  shared_examples 'a C source creator' do |expected_name|
    describe '#write' do
      it 'creates four suitably-named "base" files' do
        Dir.mktmpdir do |dir|
          struct_class.write(dir)
          expect(File.exist?(File.join(dir, 'base', "struct_#{expected_name}.h"))).to be true
          expect(File.exist?(File.join(dir, 'base', "struct_#{expected_name}.c"))).to be true
          expect(File.exist?(File.join(dir, 'base', "ruby_class_#{expected_name}.h"))).to be true
          expect(File.exist?(File.join(dir, 'base', "ruby_class_#{expected_name}.c"))).to be true
        end
      end
    end

    describe '#write_user' do
      it 'creates two suitably-named "ruby" files' do
        Dir.mktmpdir do |dir|
          struct_class.write_user(dir)
          expect(File.exist?(File.join(dir, 'ruby', "class_#{expected_name}.h"))).to be true
          expect(File.exist?(File.join(dir, 'ruby', "class_#{expected_name}.c"))).to be true
        end
      end

      it 'does not over-write existing "ruby" files' do
        Dir.mktmpdir do |dir|
          FileUtils.mkdir_p File.join(dir, 'ruby')
          target_files = %w[h c].map { |e| File.join(dir, 'ruby', "class_#{expected_name}.#{e}") }
          target_files.each do |target_file|
            File.open(target_file, 'wb') do |f|
              f.puts 'Leave me alone!'
            end
          end

          struct_class.write_user(dir)

          target_files.each do |target_file|
            lines = File.readlines(target_file)
            expect(lines).to eql ["Leave me alone!\n"]
          end
        end
      end
    end
  end

  describe 'minimal struct' do
    subject(:struct_class) { described_class.new('bar', parent_lib: libdef) }

    it 'has default names' do
      expect(struct_class.short_name).to eql 'bar'
      expect(struct_class.struct_name).to eql 'Bar'
      expect(struct_class.rb_class_name).to eql 'Bar'

      expect(struct_class.lib_short_name).to eql 'foo'
      expect(struct_class.lib_module_name).to eql 'Foo'
      expect(struct_class.full_class_name).to eql 'Foo_Bar'
      expect(struct_class.full_class_name_ruby).to eql 'Foo::Bar'
    end

    it 'has empty attributes array' do
      expect(struct_class.attributes).to be_empty
    end

    it 'has empty init_params array' do
      expect(struct_class.init_params).to be_empty
    end

    it 'has no narrays' do
      expect(struct_class.any_narray?).to be false
      expect(struct_class.narray_attributes).to be_empty
    end

    it 'has no attributes requiring malloc' do
      expect(struct_class.any_alloc?).to be false
      expect(struct_class.alloc_attributes).to be_empty
    end

    it 'has no attributes requiring initialisation' do
      expect(struct_class.needs_init?).to be false
    end

    it 'has no "simple" attributes' do
      expect(struct_class.simple_attributes).to be_empty
      expect(struct_class.simple_attributes_with_init).to be_empty
    end

    it_behaves_like 'a C source creator', 'bar'
  end
end
