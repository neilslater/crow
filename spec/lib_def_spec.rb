# frozen_string_literal: true

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

  let(:demo_table_attributes) do
    [
      { name: 'narr_data', ruby_name: 'data', ctype: :NARRAY_DOUBLE,
        init: { rank_expr: '2', shape_exprs: ['$width', '$height'] } },
      { name: 'narr_summary', ruby_name: 'summary', ctype: :NARRAY_DOUBLE,
        init: { rank_expr: '1', shape_exprs: ['$width'] } },
      { name: 'narr_counts', ruby_name: 'counts', ctype: :NARRAY_INT32,
        init: { rank_expr: '1', shape_exprs: ['$height'] } },
      { name: 'narr_inverse', ruby_name: 'inverse', ctype: :NARRAY_FLOAT,
        init: { rank_expr: '2', shape_exprs: ['$height', '$width'] } }
    ]
  end

  let(:demo_table) do
    {
      name: 'table',
      attributes: demo_table_attributes,
      init_params: [
        { name: 'width', ctype: :int, init: { validate_min: 1, validate_max: 10 } },
        { name: 'height', ctype: :int, init: { validate_min: 1, validate_max: 20 } }
      ]
    }
  end

  let(:demo_baz) do
    {
      name: 'baz',
      attributes: [
        { name: 'num_things', ctype: :int, init: { expr: '.' } },
        { name: 'things', ctype: :int, pointer: true, ruby_read: false,
          init: { size_expr: '.num_things', expr: '0' } }
      ],
      init_params: [{ name: 'num_things', ctype: :int }]
    }
  end

  let(:demo_bar) do
    {
      name: 'bar',
      attributes: [
        { name: 'hi', ctype: :int, ruby_write: true, init: { expr: '.' } }
      ],
      init_params: [{ name: 'hi', ctype: :int }]
    }
  end

  let(:demo_structs) do
    [
      demo_bar,
      demo_baz,
      demo_table
    ]
  end

  let(:libdef_b) do
    Crow::LibDef.new(
      'foo',
      structs: demo_structs
    )
  end

  let(:c_source) do
    <<~CENDS
      #include "ruby/class_bar.h"

      VALUE bar_rbobject__hi_doubled( VALUE self ) {
        Bar *bar = get_bar_struct( self );
        return INT2NUM( bar->hi * 2 );
      }

      void init_class_bar_ext() {
        rb_define_method( Foo_Bar, "hi_doubled", bar_rbobject__hi_doubled, 0 );
        return;
      }
    CENDS
  end

  let(:c_libh_source) do
    <<~CLIBHENDS
      #ifndef LIB_STRUCT_BAR_H
      #define LIB_STRUCT_BAR_H

      #include "base/all_structs.h"

      int bar__count( Bar *bar );

      #endif
    CLIBHENDS
  end

  let(:c_lib_source) do
    <<~CLIBENDS
      #include "lib/bar.h"

      int bar__count( Bar *bar ) {
        return bar->hi * 7;
      }
    CLIBENDS
  end

  let(:c_rb_source) do
    <<~CRBENDS
      #include "ruby/class_bar.h"

      VALUE bar_rbobject__hi_user( VALUE self ) {
        Bar *bar = get_bar_struct( self );
        return DBL2NUM( bar__count( bar ) * 0.25 );
      }

      void init_class_bar_ext() {
        rb_define_method( Foo_Bar, "hi_user", bar_rbobject__hi_user, 0 );
        return;
      }
    CRBENDS
  end

  def run_command(command)
    output, exit_code = Open3.popen3(command) do |_stdin, stdout, _stderr, wait_thr|
      [stdout.read, wait_thr.value.to_i]
    end

    [output, exit_code]
  end

  def build(_lib_name, dir)
    command = "cd #{dir} && BUNDLE_GEMFILE=#{dir}/Gemfile bundle install"
    output, exit_code = run_command(command)
    puts output if exit_code > 0
    expect(exit_code).to be 0
    expect(output).to include 'Bundle complete!'
  end

  def run_rake(_lib_name, dir, task)
    command = "cd #{dir} && BUNDLE_GEMFILE=#{dir}/Gemfile bundle exec rake #{task} 2>&1"
    output, exit_code = run_command(command)
    puts output if exit_code > 0
    expect(exit_code).to be 0
    output
  end

  def build_and_run_rake(lib_name, dir, task = '')
    build(lib_name, dir)
    run_rake(lib_name, dir, task)
  end

  def compile_project(lib_name, dir)
    result = build_and_run_rake lib_name, dir, 'compile'
    expect(result).to include 'compiling'
    # Temp skip this due to warning:
    # ld: warning: -undefined dynamic_lookup may not work with chained fixups
    # expect(result).to_not include('warning'), result
    expect(result).to include "linking shared-object #{lib_name}/#{lib_name}"
  end

  def run_script_in_project(_lib_name, dir, script)
    command = "cd #{dir} && BUNDLE_GEMFILE=#{dir}/Gemfile bundle exec #{script}"
    output, exit_code = run_command(command)
    puts output if exit_code > 0
    expect(exit_code).to be 0
    output
  end

  def run_ruby_in_project(lib_name, dir, ruby_script)
    ruby_script = %(require "#{lib_name}"; #{ruby_script})
    run_script_in_project(lib_name, dir, "ruby -Ilib -e '#{ruby_script}'")
  end

  shared_examples 'a source code generator' do |lib_name, struct_names|
    describe '#create_project' do
      it 'creates C source files for the Ruby module' do
        Dir.mktmpdir do |dir|
          subject.create_project(dir)

          c_path = File.join(dir, 'ext', lib_name)
          expect(File.exist?(File.join(c_path, 'base', "ruby_module_#{lib_name}.h"))).to be true
          expect(File.exist?(File.join(c_path, 'base', "ruby_module_#{lib_name}.c"))).to be true
          expect(File.exist?(File.join(c_path, "#{lib_name}.c"))).to be true
        end
      end

      it 'creates four base C files for each struct' do
        Dir.mktmpdir do |dir|
          subject.create_project(dir)

          c_path = File.join(dir, 'ext', lib_name)

          struct_names.each do |expected_name|
            expect(File.exist?(File.join(c_path, 'base', "struct_#{expected_name}.h"))).to be true
            expect(File.exist?(File.join(c_path, 'base', "struct_#{expected_name}.c"))).to be true
            expect(File.exist?(File.join(c_path, 'base', "ruby_class_#{expected_name}.h"))).to be true
            expect(File.exist?(File.join(c_path, 'base', "ruby_class_#{expected_name}.c"))).to be true
          end
        end
      end

      it 'creates two "ruby" C files for each struct' do
        Dir.mktmpdir do |dir|
          subject.create_project(dir)

          c_path = File.join(dir, 'ext', lib_name)

          struct_names.each do |expected_name|
            expect(File.exist?(File.join(c_path, 'ruby', "class_#{expected_name}.h"))).to be true
            expect(File.exist?(File.join(c_path, 'ruby', "class_#{expected_name}.c"))).to be true
          end
        end
      end

      it 'creates a spec file for each struct' do
        Dir.mktmpdir do |dir|
          subject.create_project(dir)

          spec_path = File.join(dir, 'spec')

          struct_names.each do |expected_name|
            expect(File.exist?(File.join(spec_path, "#{expected_name}_spec.rb"))).to be true
          end
        end
      end

      it 'copies boilerplate files into the project' do
        Dir.mktmpdir do |dir|
          subject.create_project(dir)

          expect(File.exist?(File.join(dir, 'data', 'README.txt'))).to be true
          expect(File.exist?(File.join(dir, 'Gemfile'))).to be true
          expect(File.exist?(File.join(dir, 'LICENSE.txt'))).to be true
          expect(File.exist?(File.join(dir, 'Rakefile'))).to be true
          expect(File.exist?(File.join(dir, 'README.md'))).to be true
        end
      end

      it 'copies standard C files into the project' do
        Dir.mktmpdir do |dir|
          subject.create_project(dir)

          c_path = File.join(dir, 'ext', lib_name)
          expect(File.exist?(File.join(c_path, 'util', 'narray_helper.c'))).to be true
          expect(File.exist?(File.join(c_path, 'util', 'narray_helper.h'))).to be true
          expect(File.exist?(File.join(c_path, 'extconf.rb'))).to be true
          expect(File.exist?(File.join(c_path, 'util', 'mt.c'))).to be true
          expect(File.exist?(File.join(c_path, 'util', 'mt.h'))).to be true
          expect(File.exist?(File.join(c_path, 'util', 'ruby_helpers.c'))).to be true
          expect(File.exist?(File.join(c_path, 'util', 'ruby_helpers.h'))).to be true
          expect(File.exist?(File.join(c_path, 'base', 'shared_vars.h'))).to be true
          expect(File.exist?(File.join(c_path, 'base', 'all_structs.h'))).to be true
        end
      end

      it 'can build a project and compile the C files' do
        Dir.mktmpdir do |dir|
          subject.create_project(dir)
          compile_project(lib_name, dir)
          result = run_ruby_in_project(lib_name, dir, %(puts "Loaded OK"))
          expect(result.chomp).to end_with 'Loaded OK'
        end
      end

      it 'can run default rake task and pass tests' do
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

    it 'creates a module in C extension, named after the library' do
      Dir.mktmpdir do |dir|
        subject.create_project(dir)
        compile_project('foo', dir)

        result = run_ruby_in_project('foo', dir, %(p [Foo, Foo.class]))
        expect(result.chomp).to end_with '[Foo, Module]'
      end
    end

    it 'creates a class in C extension, with correct name and properties' do
      Dir.mktmpdir do |dir|
        subject.create_project(dir)
        compile_project('foo', dir)

        result = run_ruby_in_project('foo', dir, %(p [Foo::Bar, Foo::Bar.class]))
        expect(result.chomp).to end_with '[Foo::Bar, Class]'

        result = run_ruby_in_project('foo', dir, %(f = Foo::Bar.new; p f.hi))
        expect(result.chomp).to end_with '0'

        result = run_ruby_in_project('foo', dir, %(f = Foo::Bar.new; f.hi = -17; p f.hi))
        expect(result.chomp).to end_with '-17'
      end
    end

    it 'creates a spec file for testing Foo::Bar' do
      Dir.mktmpdir do |dir|
        subject.create_project(dir)
        compile_project('foo', dir)

        result = run_script_in_project('foo', dir, 'rspec -f d -c spec/bar_spec.rb')
        expect(result).to include("\nFoo::Bar\n")
        expect(result).to match(/\d+ examples?, 0 failures/)

        # Individual spec examples we expect
        expected_specs = ['is a valid Class']
        expected_specs.each do |spec_text|
          expect(result).to include(spec_text)
        end
      end
    end

    it 'allows user source code to be added in "ruby" dir' do
      Dir.mktmpdir do |dir|
        subject.create_project(dir)
        File.open(File.join(dir, 'ext', 'foo', 'ruby', 'class_bar.c'), 'w') do |f|
          f.puts c_source
        end
        compile_project('foo', dir)

        result = run_ruby_in_project('foo', dir, %(f = Foo::Bar.new; f.hi = -17; p f.hi_doubled))
        expect(result.chomp).to end_with '-34'
      end
    end

    it 'allows user source code to be added in "lib" dir' do
      Dir.mktmpdir do |dir|
        subject.create_project(dir)

        File.open(File.join(dir, 'ext', 'foo', 'lib', 'bar.h'), 'w') do |f|
          f.puts c_libh_source
        end

        File.open(File.join(dir, 'ext', 'foo', 'lib', 'bar.c'), 'w') do |f|
          f.puts c_lib_source
        end

        File.open(File.join(dir, 'ext', 'foo', 'ruby', 'class_bar.c'), 'w') do |f|
          f.puts c_rb_source
        end

        compile_project('foo', dir)

        result = run_ruby_in_project('foo', dir, %(f = Foo::Bar.new; f.hi = -3; p f.hi_user))
        expect(result.chomp).to end_with '-5.25'
      end
    end
  end

  describe 'libdef with C array and NArray' do
    subject { libdef_b }

    it_behaves_like 'a source code generator', 'foo', %w[bar baz table]
  end
end
