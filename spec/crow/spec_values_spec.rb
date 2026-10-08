# frozen_string_literal: true

require 'spec_helper'

describe Crow::SpecValues, :aggregate_failures do
  def structure(field, params = [])
    Crow::StructClass.new('item', attributes: [field], init_params: params)
  end

  it 'uses upper bounds when the old default of one is invalid' do
    model = structure({ name: 'number', ctype: :int, init: { expr: '.' } },
                      [{ name: 'number', ctype: :int, init: { validate_max: -2 } }])
    expect(model.spec_arguments).to eq [-2]
    expect(model.spec_expected(model.attributes.first)).to eq '-2'
  end

  it 'uses the same parameter value in expected arithmetic' do
    model = structure({ name: 'number', ctype: :int, init: { expr: '$input * 2' } },
                      [{ name: 'input', ctype: :int, init: { validate_min: 3 } }])
    expect(model.spec_expected(model.attributes.first)).to eq '6'
  end

  { VALUE: 'nil', long: '0', double: '0.0' }.each do |type, expected|
    it "renders a Ruby literal for #{type}" do
      model = structure(name: 'value', ctype: type)
      expect(model.spec_expected(model.attributes.first)).to eq expected
    end
  end

  it 'uses nil for a VALUE constructor parameter' do
    model = structure({ name: 'value', ctype: :VALUE, init: { expr: '.' } },
                      [{ name: 'value', ctype: :VALUE }])
    expect(model.spec_arguments).to eq [nil]
    expect(model.spec_expected(model.attributes.first)).to eq 'nil'
  end

  [
    { ctype: :int, pointer: true },
    { ctype: :NARRAY_FLOAT },
    { ctype: :int, init: { validate_min: 'MIN' } },
    { ctype: :int, init: { validate_min: 0.1, validate_max: 0.5 } },
    { ctype: :uint, init: { validate_max: -1 } }
  ].each do |options|
    it "requires a user fixture for #{options.inspect}" do
      model = structure({ name: 'value', ctype: :int }, [options.merge(name: 'input')])
      expect(model.spec_fixture_error).not_to be_nil
    end
  end

  it 'requires a user expectation for custom native expressions' do
    model = structure(name: 'value', ctype: :int, init: { expr: 'custom()' })
    expect(model.spec_expectation_error(model.attributes.first)).to include('Unsupported')
  end

  it 'reports missing fixture references' do
    model = structure(name: 'value', ctype: :int, init: { expr: '$missing' })
    expect(model.spec_expectation_error(model.attributes.first)).not_to be_nil
  end

  it 'renders an explicit pending example for unsupported native expectations' do
    Dir.mktmpdir do |dir|
      model = structure(name: 'value', ctype: :int, init: { expr: 'custom()' })
      model.write_specs(dir)
      expect(File.read(File.join(dir, 'item_spec.rb'))).to include('skip "Supply a user expectation')
    end
  end
end
