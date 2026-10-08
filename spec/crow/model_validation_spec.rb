# frozen_string_literal: true

require 'spec_helper'

describe Crow::ModelValidation, :aggregate_failures do
  let(:field) { { name: 'values', ctype: :int } }
  let(:model) { Crow::LibDef.new('fixture', structs: [{ name: 'item', attributes: [field] }]) }

  def snapshot(root)
    Dir.glob("#{root}/**/*", File::FNM_DOTMATCH).select { |path| File.file?(path) }
       .to_h { |path| [path.delete_prefix(root), File.binread(path)] }
  end

  shared_examples 'rejects without writes' do |options|
    let(:field) { super().merge(options) }

    it "rejects #{options.inspect} before creating a target" do
      Dir.mktmpdir do |dir|
        target = File.join(dir, 'absent')
        expect { model.create_project(target) }.to raise_error(ArgumentError)
        expect(File.exist?(target)).to be false
      end
    end

    it "preserves all existing files for #{options.inspect}" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'Rakefile'), 'custom tasks')
        expect { model.create_project(dir) }.to raise_error(ArgumentError)
        expect(snapshot(dir)).to eq('/Rakefile' => 'custom tasks')
      end
    end
  end

  [
    { pointer: true },
    { pointer: true, store: true, init: { size_expr: '2' } },
    { pointer: true, ruby_write: true, init: { size_expr: '2' } },
    { ctype: :char, pointer: true, init: { size_expr: '2' } },
    { ctype: :VALUE, pointer: true },
    { ctype: :NARRAY_DOUBLE, pointer: true },
    { ctype: :NARRAY_DOUBLE, ruby_write: true },
    { ctype: :NARRAY_DOUBLE, init: { rank_expr: '1', shape_exprs: %w[2 3] } },
    { ctype: :NARRAY_DOUBLE, init: { rank_expr: '2', shape_exprs: ['2'] } },
    { ctype: :NARRAY_DOUBLE, init: { shape_expr: '{2}' } },
    { ctype: :NARRAY_DOUBLE, init: { shape_expr: '{2}', shape_exprs: ['2'] } },
    { ctype: :NARRAY_DOUBLE, init: { rank_expr: '$rank' } },
    { ctype: :NARRAY_DOUBLE, init: { rank_expr: '0' } },
    { ctype: :NARRAY_DOUBLE, init: { rank_expr: '63' } },
    { ctype: :NARRAY_DOUBLE, init: { shape_exprs: [] } },
    { ctype: :NARRAY_DOUBLE, init: { shape_exprs: [''] } },
    { ctype: :NARRAY_DOUBLE, init: { shape_exprs: [2] } },
    { init: { expr: '$missing' } },
    { init: { expr: '%missing' } },
    { init: { validate_min: 3, validate_max: 2 } },
    { name: 'int' }, { name: '9name' }, { name: 'crow_state' },
    { ruby_name: 'bad-name' }, { ruby_name: 'initialize' },
    { pointer: true, init: { size_expr: 'malloc(2)' } }
  ].each do |options|
    context "with #{options.inspect}" do
      it_behaves_like 'rejects without writes', options
    end
  end

  %i[write write_user write_specs].each do |writer|
    it "validates mutable models for #{writer}" do
      Dir.mktmpdir do |dir|
        model.structs.first.add_attribute(name: 'broken', ctype: :int, pointer: true)
        expect { model.structs.first.public_send(writer, dir) }.to raise_error(ArgumentError, /size_expr/)
        expect(snapshot(dir)).to be_empty
      end
    end
  end

  it 'uses the current name for both filenames and rendered contents' do
    Dir.mktmpdir do |dir|
      model.structs.first.short_name = 'renamed'
      model.create_project(dir)
      expect(File.read(File.join(dir, 'ext/fixture/base/struct_renamed.c'))).to include('renamed__create')
    end
  end

  it 'rejects duplicate class output names' do
    model.structs << model.structs.first
    expect { model.create_project('/unused') }.to raise_error(ArgumentError, /Duplicate/)
  end

  it 'rejects duplicate exposed readers' do
    model.structs.first.add_attribute(name: 'other', ctype: :int, ruby_name: 'values')
    expect { model.create_project('/unused') }.to raise_error(ArgumentError, /Duplicate/)
  end

  it 'rejects invalid mutable constant names' do
    model.module_name = 'lowercase'
    expect { model.create_project('/unused') }.to raise_error(ArgumentError, /constant/)
  end

  it 'rejects a size-control writer even when size uses the constructor parameter' do
    struct = Crow::StructClass.new('item', attributes: [
                                     { name: 'count', ctype: :int, ruby_write: true, init: { expr: '.' } },
                                     { name: 'buffer', ctype: :int, pointer: true, init: { size_expr: '.count' } }
                                   ], init_params: [{ name: 'count', ctype: :int }])
    expect { struct.write('/unused') }.to raise_error(ArgumentError, /storage dependency/)
  end

  context 'with a late rendering failure' do
    before do
      allow(Crow::OutputPlan).to receive(:render).and_call_original
      allow(Crow::OutputPlan).to receive(:render).with(/struct_dataset.c/, anything).and_raise(ArgumentError, 'late')
    end

    it 'does not apply earlier rendered files' do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'Rakefile'), 'custom tasks')
        expect { model.create_project(dir) }.to raise_error(ArgumentError, 'late')
        expect(snapshot(dir)).to eq('/Rakefile' => 'custom tasks')
      end
    end
  end
end
