# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'fileutils'

require 'bundler/audit/task'
require 'rubocop/rake_task'
require 'yard'

desc 'Run Rubocop'
RuboCop::RakeTask.new

desc 'Update and run bundle audit'
Bundler::Audit::Task.new

desc 'Crow unit tests'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/*_spec.rb'
  t.verbose = false
end

def demo_structs
  [
    demo_bar,
    demo_baz,
    demo_table
  ]
end

def demo_bar
  {
    name: 'bar',
    attributes: [
      { name: 'hi', ctype: :int, ruby_write: true, init: { expr: '.' } }
    ],
    init_params: [{ name: 'hi', ctype: :int }]
  }
end

def demo_baz
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

def demo_table
  {
    name: 'table',
    attributes: demo_table_attributes,
    init_params: [
      { name: 'width', ctype: :int, init: { validate_min: 1, validate_max: 10 } },
      { name: 'height', ctype: :int, init: { validate_min: 1, validate_max: 20 } }
    ]
  }
end

def demo_table_attributes
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

desc 'Create a test project'
task :demo, :out_path do |_t, args|
  out_path = args[:out_path]
  if out_path.nil?
    puts 'Missing output path'
    exit 1
  end

  out_path.strip!
  FileUtils.mkdir_p(out_path)

  require_relative 'lib/crow'

  l = Crow::LibDef.new(
    'foo',
    structs: demo_structs
  )

  l.create_project(out_path)
  puts "Wrote demo project to #{out_path}"
end

desc 'Generate YARD documentation'
YARD::Rake::YardocTask.new do |doc_task|
  doc_task.files = ['lib/crow.rb', 'lib/crow/*.rb']
end

desc 'Run full set of QC tools'
task qc: %i[bundle:audit rubocop spec]

task default: :qc
