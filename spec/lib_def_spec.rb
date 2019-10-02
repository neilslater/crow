require 'spec_helper'
require 'open3'

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

  def run_command command
    output, exit_code = Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
      [stdout.read, wait_thr.value.to_i]
    end

    [output, exit_code]
  end

  def build_and_run_rake lib_name, dir, task=''
    command = "cd #{dir} && BUNDLE_GEMFILE=#{dir}/Gemfile bundle install"
    output, exit_code = run_command "cd #{dir} && BUNDLE_GEMFILE=#{dir}/Gemfile bundle install"

    expect(exit_code).to be 0
    expect(output).to include "Bundle complete!"

    output, exit_code = run_command "cd #{dir} && BUNDLE_GEMFILE=#{dir}/Gemfile bundle exec rake #{task} 2>&1"
    expect(exit_code).to be 0
    output
  end

  def compile_project lib_name, dir
    result =  build_and_run_rake lib_name, dir, 'compile'
    # TODO: Check for compiler warnings and fail if any
    expect(result).to include "compiling"
    expect(result).to include "linking shared-object #{lib_name}/#{lib_name}"
  end

  def run_ruby_in_project lib_name, dir, ruby_script
    ruby_script = %Q{require "#{lib_name}/#{lib_name}"; #{ruby_script}}
    output, exit_code = run_command "cd #{dir} && BUNDLE_GEMFILE=#{dir}/Gemfile bundle exec ruby -Ilib -e '#{ruby_script}'"
    expect(exit_code).to be 0
    output
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

      it "can build a project and compile the C files" do
        Dir.mktmpdir do |dir|
          subject.create_project(dir)
          compile_project(lib_name, dir)
          result = run_ruby_in_project( lib_name, dir, %Q{puts "Loaded OK"} )
          expect(result.chomp).to eql "Loaded OK"
        end
      end

      it "can run default rake task and pass tests" do
        Dir.mktmpdir do |dir|
          subject.create_project(dir)
          result = build_and_run_rake(lib_name, dir)
          expect(result.chomp).to match(/\d+ examples, 0 failures/)
        end
      end
    end
  end

  describe 'minimal libdef' do
    subject { simple_libdef }

    it_behaves_like 'a source code generator', 'foo', ['bar']

    it "creates a module in C extension, named after the library" do
      Dir.mktmpdir do |dir|
        subject.create_project(dir)
        compile_project('foo', dir)

        result = run_ruby_in_project( 'foo', dir, %Q{p [Foo, Foo.class]} )
        expect(result.chomp).to eql "[Foo, Module]"
      end
    end

    it "creates a class in C extension, with correct name and properties" do
      Dir.mktmpdir do |dir|
        subject.create_project(dir)
        compile_project('foo', dir)

        result = run_ruby_in_project( 'foo', dir, %Q{p [Foo::Bar, Foo::Bar.class]} )
        expect(result.chomp).to eql "[Foo::Bar, Class]"

        result = run_ruby_in_project( 'foo', dir, %Q{f = Foo::Bar.new; p f.hi} )
        expect(result.chomp).to eql "0"

        result = run_ruby_in_project( 'foo', dir, %Q{f = Foo::Bar.new; f.hi = -17; p f.hi} )
        expect(result.chomp).to eql "-17"
      end
    end
  end
end
