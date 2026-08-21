# frozen_string_literal: true

require 'spec_helper'
require 'open3'

describe Crow::LibDef do
  describe Crow::LibTemplateRules do
    subject(:rules) { Class.new { include Crow::LibTemplateRules }.new }

    it 'skips temporary and Finder metadata files' do
      results = %w[tmp/build.o source/.DS_Store lib/code.rb].map { |path| rules.send(:skip_project_file?, path) }
      expect(results).to eq [true, true, false]
    end

    it 'identifies files whose names and contents should change' do
      results = %w[README lib/code.rb image.png].map { |path| rules.send(:change_names?, path) }
      expect(results).to eq [true, true, false]
    end

    it 'identifies user-owned source files' do
      paths = %w[ruby/class.c lib/code.c base/generated.c]
      expect(paths.map { |path| rules.send(:contains_user_code?, path) }).to eq [true, true, false]
    end

    it 'only renders source templates' do
      paths = %w[source.c header.h source.rb README.md]
      expect(paths.map { |path| rules.send(:run_template?, path) }).to eq [true, true, true, false]
    end
  end

  it 'rejects an invalid short name' do
    expect { described_class.new('not-valid') }.to raise_error RuntimeError, /cannot be used/
  end

  it 'rejects an unknown project type' do
    expect { described_class.new('foo').create_project('/unused', 'unknown') }
      .to raise_error RuntimeError, /Unknown project type/
  end

  def run_command(command)
    # Prevent the generated project's Bundler commands inheriting Crow's active bundle.
    stdout, stderr, status = Bundler.with_unbundled_env do
      Open3.capture3(command)
    end

    [stdout, stderr, status.exitstatus]
  end

  def successful_output(command)
    stdout, stderr, exit_code = run_command(command)
    expect(exit_code).to be_zero, stdout + stderr
    stdout
  end

  def build(_lib_name, dir)
    command = "cd #{dir} && BUNDLE_GEMFILE=#{dir}/Gemfile bundle install"
    output = successful_output(command)
    expect(output).to include 'Bundle complete!'
  end

  def run_rake(_lib_name, dir, task)
    command = "cd #{dir} && BUNDLE_GEMFILE=#{dir}/Gemfile bundle exec rake #{task}"
    successful_output(command)
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
    successful_output(command)
  end

  def run_ruby_in_project(lib_name, dir, ruby_script)
    ruby_script = %(require "#{lib_name}"; #{ruby_script})
    run_script_in_project(lib_name, dir, "ruby -Ilib -e '#{ruby_script}'")
  end

  def in_project(lib_definition)
    Dir.mktmpdir do |dir|
      lib_definition.create_project(dir)
      yield dir, File.join(dir, 'ext', lib_definition.short_name)
    end
  end

  def write_project_files(dir, files)
    files.each do |path_segments, contents|
      File.write(File.join(dir, *path_segments), contents)
    end
  end

  def add_user_library_sources(dir)
    write_project_files(
      dir,
      {
        %w[ext foo lib bar.h] => user_sources.fetch(:library_header),
        %w[ext foo lib bar.c] => user_sources.fetch(:library),
        %w[ext foo ruby class_bar.c] => user_sources.fetch(:ruby_binding)
      }
    )
  end

  def base_struct_files(c_path, struct_names)
    struct_names.flat_map do |name|
      %W[
        #{c_path}/base/struct_#{name}.h
        #{c_path}/base/struct_#{name}.c
        #{c_path}/base/ruby_class_#{name}.h
        #{c_path}/base/ruby_class_#{name}.c
      ]
    end
  end

  def ruby_struct_files(c_path, struct_names)
    struct_names.flat_map do |name|
      %W[#{c_path}/ruby/class_#{name}.h #{c_path}/ruby/class_#{name}.c]
    end
  end

  def generated_spec_files(dir, struct_names)
    struct_names.map { |name| File.join(dir, 'spec', "#{name}_spec.rb") }
  end

  def run_user_ruby_extension(dir)
    write_project_files(dir, %w[ext foo ruby class_bar.c] => user_sources.fetch(:extension))
    compile_project('foo', dir)
    run_ruby_in_project('foo', dir, %(f = Foo::Bar.new; f.hi = -17; p f.hi_doubled))
  end

  def run_user_c_library(dir)
    add_user_library_sources(dir)
    compile_project('foo', dir)
    run_ruby_in_project('foo', dir, %(f = Foo::Bar.new; f.hi = -3; p f.hi_user))
  end

  def regenerate_user_source(dir)
    target = File.join(dir, 'ext', 'foo', 'ruby', 'class_bar.c')
    File.write(target, "Leave me alone!\n")
    lib_definition.create_project(dir)
    File.read(target)
  end

  shared_examples 'a source code generator' do |lib_name, struct_names|
    describe '#create_project' do
      it 'creates C source files for the Ruby module' do
        in_project(lib_definition) do |_dir, c_path|
          expect(
            [
              File.join(c_path, 'base', "ruby_module_#{lib_name}.h"),
              File.join(c_path, 'base', "ruby_module_#{lib_name}.c"),
              File.join(c_path, "#{lib_name}.c")
            ]
          ).to all_exist
        end
      end

      it 'creates four base C files for each struct' do
        in_project(lib_definition) do |_dir, c_path|
          expect(base_struct_files(c_path, struct_names)).to all_exist
        end
      end

      it 'creates two "ruby" C files for each struct' do
        in_project(lib_definition) do |_dir, c_path|
          expect(ruby_struct_files(c_path, struct_names)).to all_exist
        end
      end

      it 'creates a spec file for each struct' do
        in_project(lib_definition) do |dir|
          expect(generated_spec_files(dir, struct_names)).to all_exist
        end
      end

      it 'copies boilerplate files into the project' do
        in_project(lib_definition) do |dir|
          expect(
            [
              File.join(dir, 'data', 'README.txt'),
              File.join(dir, 'Gemfile'),
              File.join(dir, 'LICENSE.txt'),
              File.join(dir, 'Rakefile'),
              File.join(dir, 'README.md')
            ]
          ).to all_exist
        end
      end

      it 'copies standard C files into the project' do
        in_project(lib_definition) do |_dir, c_path|
          expect(
            [
              File.join(c_path, 'util', 'narray_helper.c'),
              File.join(c_path, 'util', 'narray_helper.h'),
              File.join(c_path, 'extconf.rb'),
              File.join(c_path, 'util', 'mt.c'),
              File.join(c_path, 'util', 'mt.h'),
              File.join(c_path, 'util', 'ruby_helpers.c'),
              File.join(c_path, 'util', 'ruby_helpers.h'),
              File.join(c_path, 'base', 'shared_vars.h'),
              File.join(c_path, 'base', 'all_structs.h')
            ]
          ).to all_exist
        end
      end

      it 'can build a project and compile the C files' do
        in_project(lib_definition) do |dir|
          compile_project(lib_name, dir)
          result = run_ruby_in_project(lib_name, dir, %(puts "Loaded OK"))
          expect(result.chomp).to end_with 'Loaded OK'
        end
      end

      it 'can run default rake task and pass tests' do
        in_project(lib_definition) do |dir|
          result = build_and_run_rake(lib_name, dir)
          expect(result.chomp).to match(/\d+ examples, 0 failures/)
        end
      end
    end
  end

  describe 'minimal libdef' do
    subject(:lib_definition) { simple_libdef }

    let(:simple_libdef) do
      described_class.new(
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

    let(:user_sources) do
      {
        extension: <<~C,
          #include "ruby/class_bar.h"

          VALUE bar_rbobject__hi_doubled( VALUE self ) {
            Bar *bar = get_bar_struct( self );
            return INT2NUM( bar->hi * 2 );
          }

          void init_class_bar_ext() {
            rb_define_method( Foo_Bar, "hi_doubled", bar_rbobject__hi_doubled, 0 );
            return;
          }
        C
        library_header: <<~C,
          #ifndef LIB_STRUCT_BAR_H
          #define LIB_STRUCT_BAR_H

          #include "base/all_structs.h"

          int bar__count( Bar *bar );

          #endif
        C
        library: <<~C,
          #include "lib/bar.h"

          int bar__count( Bar *bar ) {
            return bar->hi * 7;
          }
        C
        ruby_binding: <<~C
          #include "ruby/class_bar.h"

          VALUE bar_rbobject__hi_user( VALUE self ) {
            Bar *bar = get_bar_struct( self );
            return DBL2NUM( bar__count( bar ) * 0.25 );
          }

          void init_class_bar_ext() {
            rb_define_method( Foo_Bar, "hi_user", bar_rbobject__hi_user, 0 );
            return;
          }
        C
      }
    end

    it_behaves_like 'a source code generator', 'foo', ['bar']

    it 'creates a module in C extension, named after the library' do
      in_project(lib_definition) do |dir|
        compile_project('foo', dir)

        result = run_ruby_in_project('foo', dir, %(p [Foo, Foo.class]))
        expect(result.chomp).to end_with '[Foo, Module]'
      end
    end

    it 'creates a class in C extension, with correct name and properties' do
      in_project(lib_definition) do |dir|
        compile_project('foo', dir)

        results = [
          run_ruby_in_project('foo', dir, %(p [Foo::Bar, Foo::Bar.class])).chomp,
          run_ruby_in_project('foo', dir, %(f = Foo::Bar.new; p f.hi)).chomp,
          run_ruby_in_project('foo', dir, %(f = Foo::Bar.new; f.hi = -17; p f.hi)).chomp
        ]
        expect(results).to match [end_with('[Foo::Bar, Class]'), end_with('0'), end_with('-17')]
      end
    end

    it 'creates a spec file for testing Foo::Bar' do
      in_project(lib_definition) do |dir|
        compile_project('foo', dir)

        result = run_script_in_project('foo', dir, 'rspec -f d -c spec/bar_spec.rb')
        expect(result).to include("\nFoo::Bar\n", 'is a valid Class').and match(/\d+ examples?, 0 failures/)
      end
    end

    it 'allows user source code to be added in "ruby" dir' do
      in_project(lib_definition) do |dir|
        expect(run_user_ruby_extension(dir).chomp).to end_with '-34'
      end
    end

    it 'allows user source code to be added in "lib" dir' do
      in_project(lib_definition) do |dir|
        expect(run_user_c_library(dir).chomp).to end_with '-5.25'
      end
    end

    it 'preserves user source code when regenerating a project' do
      in_project(lib_definition) do |dir|
        expect(regenerate_user_source(dir)).to eq "Leave me alone!\n"
      end
    end
  end

  describe 'libdef with C array and NArray' do
    subject(:lib_definition) { libdef_b }

    let(:libdef_b) { described_class.new('foo', structs: demo_structs) }

    let(:demo_structs) do
      [
        {
          name: 'bar',
          attributes: [
            { name: 'hi', ctype: :int, ruby_write: true, init: { expr: '.' } }
          ],
          init_params: [{ name: 'hi', ctype: :int }]
        },
        {
          name: 'baz',
          attributes: [
            { name: 'num_things', ctype: :int, init: { expr: '.' } },
            { name: 'things', ctype: :int, pointer: true, ruby_read: false,
              init: { size_expr: '.num_things', expr: '0' } }
          ],
          init_params: [{ name: 'num_things', ctype: :int }]
        },
        {
          name: 'table',
          attributes: [
            { name: 'narr_data', ruby_name: 'data', ctype: :NARRAY_DOUBLE,
              init: { rank_expr: '2', shape_exprs: ['$width', '$height'] } },
            { name: 'narr_summary', ruby_name: 'summary', ctype: :NARRAY_DOUBLE,
              init: { rank_expr: '1', shape_exprs: ['$width'] } },
            { name: 'narr_counts', ruby_name: 'counts', ctype: :NARRAY_INT32,
              init: { rank_expr: '1', shape_exprs: ['$height'] } },
            { name: 'narr_inverse', ruby_name: 'inverse', ctype: :NARRAY_FLOAT,
              init: { rank_expr: '2', shape_exprs: ['$height', '$width'] } }
          ],
          init_params: [
            { name: 'width', ctype: :int, init: { validate_min: 1, validate_max: 10 } },
            { name: 'height', ctype: :int, init: { validate_min: 1, validate_max: 20 } }
          ]
        }
      ]
    end

    it_behaves_like 'a source code generator', 'foo', %w[bar baz table]
  end
end
