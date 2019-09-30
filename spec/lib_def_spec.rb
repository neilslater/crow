require 'spec_helper'

describe Crow::LibDef do
  let(:simple_libdef) do
    Crow::LibDef.new(
      'foo',
      structs: [
        {
           name: 'bar',
           attributes: [
            { name: 'hi', ctype: :int, ruby_write: true }
          ]
        }
      ]
    )
  end

  shared_examples 'a source code generator' do |lib_name, struct_names|
    describe '#create_project' do
      it 'creates C source files for the Ruby module' do
        Dir.mktmpdir do |dir|
          subject.create_project(dir)

          c_path = File.join( dir, 'ext', lib_name )
          expect( File.exists?( File.join(c_path, "ruby_module_#{lib_name}.h")) ).to be true
          expect( File.exists?( File.join(c_path, "ruby_module_#{lib_name}.c")) ).to be true
          expect( File.exists?( File.join(c_path, "#{lib_name}.c")) ).to be true
        end
      end

      it 'creates four C files for each struct' do
        Dir.mktmpdir do |dir|
          subject.create_project(dir)

          c_path = File.join( dir, 'ext', lib_name )

          struct_names.each do |expected_name|
            expect( File.exists?( File.join(c_path, "struct_#{expected_name}.h")) ).to be true
            expect( File.exists?( File.join(c_path, "struct_#{expected_name}.c")) ).to be true
            expect( File.exists?( File.join(c_path, "ruby_class_#{expected_name}.h")) ).to be true
            expect( File.exists?( File.join(c_path, "ruby_class_#{expected_name}.c")) ).to be true
          end
        end
      end

      it 'copies boilerplate files into the project' do
        Dir.mktmpdir do |dir|
          subject.create_project(dir)

          expect( File.exists?( File.join(dir, "data", "README.txt")) ).to be true
          expect( File.exists?( File.join(dir, "Gemfile")) ).to be true
          expect( File.exists?( File.join(dir, "LICENSE.txt")) ).to be true
          expect( File.exists?( File.join(dir, "Rakefile")) ).to be true
          expect( File.exists?( File.join(dir, "README.md")) ).to be true
        end
      end

      it "copies standard C files into the project" do
        Dir.mktmpdir do |dir|
          subject.create_project(dir)

          c_path = File.join( dir, 'ext', lib_name )
          expect( File.exists?( File.join(c_path, "core_narray.c")) ).to be true
          expect( File.exists?( File.join(c_path, "core_narray.h")) ).to be true
          expect( File.exists?( File.join(c_path, "extconf.rb")) ).to be true
          expect( File.exists?( File.join(c_path, "mt.c")) ).to be true
          expect( File.exists?( File.join(c_path, "mt.h")) ).to be true
          expect( File.exists?( File.join(c_path, "shared_helpers.c")) ).to be true
          expect( File.exists?( File.join(c_path, "shared_helpers.h")) ).to be true
          expect( File.exists?( File.join(c_path, "shared_vars.h")) ).to be true
        end
      end
    end
  end

  describe 'minimal libdef' do
    subject { simple_libdef }

    it_behaves_like 'a source code generator', 'foo', ['bar']
  end
end
