# frozen_string_literal: true

require 'spec_helper'

describe Crow::StructContract, :aggregate_failures do
  def structure(attributes, params = [])
    Crow::StructClass.new('item', attributes: attributes, init_params: params)
  end

  it 'recovers exactly persisted constructor parameters for residual storage' do
    model = structure([{ name: 'count', ctype: :int, init: { expr: '.' } },
                       { name: 'data', ctype: :int, pointer: true, init: { size_expr: '.count' } }],
                      [{ name: 'count', ctype: :int }])
    expect(model.restored_params.keys).to eq ['count']
    expect(model.restoration_error).to be_nil
  end

  it 'orders dependent residual fields after stored inputs' do
    model = structure([{ name: 'input', ctype: :int },
                       { name: 'last', ctype: :int, store: false, init: { expr: '%middle + 1' } },
                       { name: 'middle', ctype: :int, store: false, init: { expr: '%input + 1' } }])
    expect(model.restore_order.map(&:name)).to eq %w[middle last]
    expect(model.restore_scalar_c(model.attributes.last)).to include('NUM2INT', 'rb_funcall')
  end

  it 'rejects cyclic reconstruction without rejecting ordinary generation' do
    model = structure([{ name: 'first', ctype: :int, store: false, init: { expr: '%second' } },
                       { name: 'second', ctype: :int, store: false, init: { expr: '%first' } }])
    expect(model.restoration_error).to include('cyclic')
    expect { Crow::ModelValidation.structure(model) }.not_to raise_error
  end

  it 'does not guess unavailable dimension inputs' do
    model = structure([{ name: 'data', ctype: :NARRAY_FLOAT, init: { shape_exprs: ['$width'] } }],
                      [{ name: 'width', ctype: :int }])
    expect(model.restoration_error).to include('width')
  end

  it 'preserves literal residual defaults' do
    model = structure([{ name: 'value', ctype: :VALUE, store: false }])
    expect(model.restore_scalar_c(model.attributes.first)).to eq 'Qnil'
    expect(model.restoration_error).to be_nil
  end

  it 'does not replay opaque residual initialization' do
    model = structure([{ name: 'value', ctype: :int, store: false, init: { expr: 'custom()' } }])
    expect(model.restoration_error).to include('Unsupported')
  end

  it 'does not infer a parameter from a transformed or differently typed field' do
    model = structure([{ name: 'width', ctype: :double, init: { expr: '$width' } },
                       { name: 'other', ctype: :int, init: { expr: '$width + 1' } }],
                      [{ name: 'width', ctype: :int }])
    expect(model.restored_params).to be_empty
  end
end
