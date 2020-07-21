require 'spec_helper'

describe Crow::StructClass do
  let(:libdef) { Crow::LibDef.new('foo') }

  shared_examples 'a C source creator' do |expected_name|
    describe '#write' do
      it 'creates four suitably-named "base" files' do
        Dir.mktmpdir do |dir|
          subject.write(dir)
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
          subject.write_user(dir)
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

          subject.write_user(dir)

          target_files.each do |target_file|
            lines = File.readlines(target_file)
            expect(lines).to eql ["Leave me alone!\n"]
          end
        end
      end
    end
  end

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

    it_behaves_like 'a C source creator', 'bar'
  end
end
