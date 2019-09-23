require 'spec_helper'

describe Crow::Expression do
  let(:libdef) do
    Crow::LibDef.new('foo',
      structs: [
        { name: 'bar',
          struct_name: 'Bar',
          rb_class_name: 'Foo_Bar',
          attributes: [
            { name: 'num', :ctype => :int }
          ],
          init_params: [
            { name: 'x', ctype: :int },
            { name: 'y', ctype: :char }
          ]
        }
      ]
    )
  end

  context 'template expression' do
    it 'can substitute attributes using %' do
      expr = Crow::Expression.new '// %num', libdef.structs.first.attributes

      expect(expr.as_c_code).to eql '// bar->num'
    end

    it 'can substitute parameters using $' do
      expr = Crow::Expression.new '// $x', libdef.structs.first.attributes, libdef.structs.first.init_params

      expect(expr.as_c_code).to eql '// x'
    end
  end
end
