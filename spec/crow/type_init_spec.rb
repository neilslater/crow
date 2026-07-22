# frozen_string_literal: true

require 'spec_helper'

describe Crow::TypeInit do
  let(:container) { Crow::StructClass.new('foo') }
  let(:type_map) { Crow::TypeMapFactory.create_typemap(name: 'x', ctype: :int, parent_struct: container, init: init) }

  context 'with an invalid parent type map' do
    it 'rejects it' do
      expect { described_class.new(parent_typemap: Object.new) }
        .to raise_error ArgumentError, 'parent_typemap must be a Crow::TypeMap'
    end
  end

  describe 'validation expressions' do
    where = {
      {} => ['( 1 )', '( 0 )'],
      { validate_min: 2 } => ['( value >= 2 )', '( value < 2 )'],
      { validate_max: 8 } => ['( value <= 8 )', '( value > 8 )'],
      { validate_min: 2, validate_max: 8 } => ['( value >= 2 && value <= 8 )', '( value < 2 || value > 8 )']
    }

    where.each do |options, expected|
      context "with #{options.empty? ? 'no limits' : options}" do
        let(:init) { options }

        it 'generates matching success and failure conditions' do
          conditions = [type_map.validate_condition_c('value'), type_map.validate_fail_condition_c('value')]
          expect(conditions).to eq expected
        end
      end
    end
  end

  describe Crow::TypeInit::Pointer do
    let(:container) do
      Crow::StructClass.new('foo', attributes: [{ name: 'count', ctype: :int }],
                                   init_params: [{ name: 'count', ctype: :int }])
    end

    it 'uses a literal size expression unchanged' do
      pointer = Crow::TypeMapFactory.create_typemap(
        name: 'values', ctype: :int, pointer: true, parent_struct: container, init: { size_expr: '4' }
      )

      expect(pointer.init.size_expr_c).to eq '4'
    end

    it 'resolves a relative size against the struct or its initialization parameter' do
      pointer = Crow::TypeMapFactory.create_typemap(
        name: 'values', ctype: :int, pointer: true, parent_struct: container, init: { size_expr: '.count' }
      )

      expressions = [pointer.init.size_expr_c, pointer.init.size_expr_c(init_context: true)]
      expect(expressions).to eq ['foo->count', 'count']
    end
  end

  describe Crow::TypeInit::NArray do
    it 'preserves an explicit shape expression' do
      narray = Crow::TypeMapFactory.create_typemap(
        name: 'values', ctype: :NARRAY_FLOAT, parent_struct: container,
        init: { rank_expr: '2', shape_expr: '{ 2, 3 }' }
      )

      expect(narray.init.shape_expr_c).to eq '{ 2, 3 }'
    end

    it 'uses a temporary shape for per-dimension expressions' do
      narray = Crow::TypeMapFactory.create_typemap(
        name: 'values', ctype: :NARRAY_FLOAT, parent_struct: container,
        init: { rank_expr: '2', shape_exprs: %w[2 3] }
      )

      expect(narray.init.shape_expr_c).to eq 'foo_values_shape'
    end

    it 'defaults every dimension to one' do
      narray = Crow::TypeMapFactory.create_typemap(
        name: 'values', ctype: :NARRAY_FLOAT, parent_struct: container, init: { rank_expr: '3' }
      )

      expect(narray.init.shape_expr_c).to eq '{ 1, 1, 1 }'
    end
  end
end
