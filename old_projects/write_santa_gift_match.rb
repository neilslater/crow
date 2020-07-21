require 'crow'

d = '/Users/neilslater/personal/kaggle/santa_gift_match/sgm/ext/sgm'

m = Crow::LibDef.new('sgm', {
                       structs: [
                         { name: 'child_wishlist',
                           attributes: [
                             { name: 'narr_items', ruby_name: 'items', ctype: :NARRAY_INT_32, ptr_cache: 'items', rank_expr: '2', shape_var: 'items_shape', shape_exprs: %w[10 1000000] }
                           ],
                           init_params: [] },

                         { name: 'gift_goodkids',
                           attributes: [
                             { name: 'narr_items', ruby_name: 'items', ctype: :NARRAY_INT_32, ptr_cache: 'items', rank_expr: '2', shape_var: 'items_shape', shape_exprs: %w[1000 1000] }
                           ],
                           init_params: [] },

                         { name: 'scores',
                           attributes: [
                             { name: 'narr_table', ruby_name: 'table', ctype: :NARRAY_INT_16, ptr_cache: 'table', rank_expr: '2', shape_var: 'table_shape', shape_exprs: %w[1000 1000000] }
                           ],
                           init_params: [] },

                         { name: 'child_gift',
                           attributes: [
                             { name: 'narr_gift_ids', ruby_name: 'gift_ids', ctype: :NARRAY_INT_16, ptr_cache: 'gift_ids', rank_expr: '1', shape_var: 'gift_ids_shape', shape_exprs: ['1000000'] }
                           ],
                           init_params: [] },

                         { name: 'gift_child',
                           attributes: [
                             { name: 'narr_child_ids', ruby_name: 'child_ids', ctype: :NARRAY_INT_16, ptr_cache: 'child_ids', rank_expr: '1', shape_var: 'child_ids_shape', shape_exprs: ['1000000'] }
                           ],
                           init_params: [] }
                       ]
                     })

m.create_project('/Users/neilslater/personal/kaggle/santa_gift_match/sgm')
puts "SantaGiftMatch: #{d}"
