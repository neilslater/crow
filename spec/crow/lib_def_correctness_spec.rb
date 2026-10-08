# frozen_string_literal: true

require 'spec_helper'
require 'open3'
require_relative '../fixtures/correctness/models'

describe Crow::LibDef do
  let(:fixtures) { File.expand_path('../fixtures/correctness', __dir__) }

  def execute(directory, *command)
    output, status = Bundler.with_unbundled_env do
      Open3.capture2e(*command, chdir: directory)
    end
    expect(status.success?).to be(true), output
    output
  end

  def install_instrumentation(directory)
    ext = File.join(directory, 'ext/contract')
    FileUtils.cp(File.join(fixtures, 'bindings.c'), File.join(ext, 'ruby/class_buffers.c'))
    %w[allocator.h allocator.c].each { |file| FileUtils.cp(File.join(fixtures, file), File.join(ext, file)) }
    instrument_allocator(File.join(ext, 'base/struct_buffers.c'))
    install_examples(directory)
  end

  def install_examples(directory)
    examples = File.read(File.join(fixtures, 'examples_spec.rb'))
    contents = "require 'helpers'\n#{examples}\n"
    contents << "describe Contract do\n  it_behaves_like 'native correctness contracts'\nend\n"
    File.write(File.join(directory, 'spec/correctness_spec.rb'), contents)
  end

  def instrument_allocator(path)
    contents = File.read(path).gsub('ruby_xcalloc(', 'test_calloc(')
                   .gsub('ruby_xmalloc(', 'test_malloc(').gsub('xfree(', 'test_free(')
    File.write(path, "#include \"allocator.h\"\n#{contents}")
  end

  def expect_generated_project(dir)
    execute(dir, 'bundle', 'install')
    execute(dir, 'bundle', 'exec', 'rake', 'compile')
    output = execute(dir, 'bundle', 'exec', 'rspec')
    expect(output).to include('0 failures')
    expect(output).not_to include('pending')
  end

  it 'compiles and exercises the accepted storage, wrapper and failure contracts' do
    Dir.mktmpdir('crow-correctness-') do |dir|
      described_class.new('contract', structs: CorrectnessModels.models).create_project(dir)
      install_instrumentation(dir)
      expect_generated_project(dir)
    end
  end
end
