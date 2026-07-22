# frozen_string_literal: true

require 'spec_helper'

describe Crow::Expression do
  let(:libdef) do
    Crow::LibDef.new('foo',
                     structs: [
                       { name: 'bar',
                         struct_name: 'Bar',
                         rb_class_name: 'Foo_Bar',
                         attributes: [
                           { name: 'num', ctype: :int }
                         ],
                         init_params: [
                           { name: 'x', ctype: :int },
                           { name: 'y', ctype: :char }
                         ] }
                     ])
  end

  context 'with a template expression' do
    it 'can substitute attributes using %' do
      expr = described_class.new '// %num', libdef.structs.first.attributes

      expect(expr.as_c_code).to eql '// bar->num'
    end

    it 'can substitute parameters using $' do
      expr = described_class.new '// $x', libdef.structs.first.attributes, libdef.structs.first.init_params

      expect(expr.as_c_code).to eql '// x'
    end

    it 'rejects unknown attributes' do
      expr = described_class.new '%missing', libdef.structs.first.attributes

      expect { expr.as_c_code }.to raise_error RuntimeError, /Attribute missing not found.*num/
    end

    it 'rejects unknown parameters' do
      expr = described_class.new '$missing', libdef.structs.first.attributes, libdef.structs.first.init_params

      expect { expr.as_c_code }.to raise_error RuntimeError, /Param missing not found.*x, y/
    end

    it 'evaluates an expression using safe test values for attributes and parameters' do
      expr = described_class.new '%num + $x', libdef.structs.first.attributes, libdef.structs.first.init_params

      expect(expr.as_ruby_test_value).to eq 2
    end

    it 'rejects unknown attributes when producing a Ruby test value' do
      expr = described_class.new '%missing', libdef.structs.first.attributes

      expect { expr.as_ruby_test_value }.to raise_error RuntimeError, /Attribute missing not found.*num/
    end

    it 'rejects unknown parameters when producing a Ruby test value' do
      expr = described_class.new '$missing', libdef.structs.first.attributes, libdef.structs.first.init_params

      expect { expr.as_ruby_test_value }.to raise_error RuntimeError, /Param missing not found.*x, y/
    end
  end
end
