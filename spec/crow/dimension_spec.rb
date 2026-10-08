# frozen_string_literal: true

require 'spec_helper'

describe Crow::Dimension, :aggregate_failures do
  let(:struct) do
    Crow::StructClass.new('item', attributes: [{ name: 'count', ctype: :uint }],
                                  init_params: [{ name: 'length', ctype: :int }])
  end

  it 'emits integer arithmetic without native intermediate overflow' do
    expression = described_class.new('(%count + +$length) * 2 - -1 / 1', struct)
    expect(expression.ruby_c('data')).to include('UINT2NUM( data->count )', 'INT2NUM( length )', 'rb_funcall')
    expect(expression.references).to eq ['%count', '$length']
  end

  ['(1; 2)', '1; 2', '1.5', '1 << 2', '~1', 'unknown', '$missing', '%missing', ''].each do |text|
    it "rejects unsupported dimension #{text.inspect}" do
      expect { described_class.new(text, struct) }.to raise_error(ArgumentError)
    end
  end
end
