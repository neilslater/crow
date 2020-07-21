require 'crow'
m = Crow::LibDef.new('container', {
                       structs: [
                         { name: 'content',
                           attributes: [
                             { name: 'numbers', ctype: :NARRAY_INT_32, ptr_cache: 'numptr', rank_expr: '2', shape_var: 'numshape', shape_exprs: ['$n+2', '$n+3'] },
                             { name: 'count', ctype: :int, default: '0', init_expr: '$n', ruby_write: true },
                             { name: 'things', ctype: :double, pointer: true, size_expr: '%count' }
                           ],
                           init_params: [{ name: 'n', ctype: :int }] }
                       ]
                     })
m.structs.first.write('/tmp')
puts 'Test 1: OK'
