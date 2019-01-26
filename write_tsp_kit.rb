require 'crow'

d = '/Users/neilslater/personal/gems/tsp_kit'

m = Crow::LibDef.new( 'tsp_kit', {
  :structs => [
    { :name => 'euclidean_nodes',
      :attributes => [
        {:name =>'num_nodes', :ctype => :int, :init_expr => '$num_nodes' },
        {:name =>'num_dims', :ctype => :int, :init_expr => '$num_dims' },
        {:name =>'narr_locations', :ruby_name => 'locations', :ctype=>:NARRAY_DOUBLE, :ptr_cache => 'locations', :rank_expr => '2', :shape_var => 'locations_shape', :shape_exprs => [ '$num_dims', '$num_nodes' ] },
        ],
      :init_params => [{:name=>'num_nodes',:ctype=>:int}, {:name=>'num_dims',:ctype=>:int}]
    },

    { :name => 'weight_matrix',
      :attributes => [
        {:name =>'num_nodes', :ctype => :int, :init_expr => '$num_nodes' },
        {:name =>'narr_weights', :ruby_name => 'weights', :ctype=>:NARRAY_DOUBLE, :ptr_cache => 'weights', :rank_expr => '2', :shape_var => 'weights_shape', :shape_exprs => [ '$num_nodes', '$num_nodes' ] },
        ],
      :init_params => [{:name=>'num_nodes',:ctype=>:int}]
    },

    { :name => 'distance_rank',
      :attributes => [
        {:name =>'num_nodes', :ctype => :int, :init_expr => '$num_nodes' },
        {:name =>'max_rank', :ctype => :int, :init_expr => '$max_rank' },
        {:name =>'narr_closest_nodes', :ruby_name => 'closest_nodes', :ctype=>:NARRAY_INT_32, :ptr_cache => 'closest_nodes', :rank_expr => '2', :shape_var => 'closest_nodes_shape', :shape_exprs => [ '$max_rank', '$num_nodes' ] },
        ],
      :init_params => [{:name=>'num_nodes',:ctype=>:int}, {:name=>'max_rank',:ctype=>:int}]
    },

    { :name => 'solution',
      :attributes => [
        {:name =>'num_nodes', :ctype => :int, :init_expr => '$num_nodes' },
        {:name =>'narr_ids', :ruby_name => 'ids', :ctype=>:NARRAY_INT_32, :ptr_cache => 'ids', :rank_expr => '1', :shape_var => 'ids_shape', :shape_exprs => [ '$num_nodes' ] },
        {:name =>'narr_node_idx', :ruby_name => 'node_idx', :ctype=>:NARRAY_INT_32, :ptr_cache => 'node_idx', :rank_expr => '1', :shape_var => 'node_idx_shape', :shape_exprs => [ '$num_nodes' ] },
      ],
      :init_params => [{:name=>'num_nodes',:ctype=>:int}]
    },

    { :name => 'greedy_solver',
      :attributes => [
        {:name =>'num_nodes', :ctype => :int, :init_expr => '$num_nodes' },
        {:name =>'max_section_id', :ctype => :int, :init_expr => '0' },
        {:name =>'route_start', :ctype => :int, :init_expr => '-1', :ruby_read => false },
        {:name =>'count_links', :ctype => :int, :init_expr => '0', :ruby_read => false },
        {:name =>'route_link_left', :ctype=> :int, :pointer => true, :size_expr => '$num_nodes', :init_expr => '-1', :ruby_read => false },
        {:name =>'route_link_right', :ctype=> :int, :pointer => true, :size_expr => '$num_nodes', :init_expr => '-1', :ruby_read => false },
        {:name =>'path_section_id', :ctype=> :int, :pointer => true, :size_expr => '$num_nodes', :init_expr => '-1', :ruby_read => false }
      ],
      :init_params => [{:name=>'num_nodes',:ctype=>:int}]
    },

    { :name => 'one_tree',
      :attributes => [
        {:name =>'num_nodes', :ctype => :int, :init_expr => '$num_nodes' },
        {:name =>'narr_node_penalties', :ruby_name => 'node_penalties', :ctype=>:NARRAY_DOUBLE, :ptr_cache => 'node_penalties', :rank_expr => '1', :shape_var => 'node_penalties_shape', :shape_exprs => [ '$num_nodes' ] },
        {:name =>'narr_node_ids', :ruby_name => 'node_ids', :ctype=>:NARRAY_INT_32, :ptr_cache => 'node_ids', :rank_expr => '1', :shape_var => 'node_ids_shape', :shape_exprs => [ '$num_nodes + 2' ] },
        {:name =>'narr_parents', :ruby_name => 'parents', :ctype=>:NARRAY_INT_32, :ptr_cache => 'parents', :rank_expr => '1', :shape_var => 'parents_shape', :shape_exprs => [ '$num_nodes + 2' ] },

        # These are buffers used to help build the tree
        {:name =>'q', :ctype=> :int, :pointer => true, :size_expr => '$num_nodes', :init_expr => '1', :ruby_read => false },
        {:name =>'c', :ctype=> :double, :pointer => true, :size_expr => '$num_nodes', :init_expr => 'OT_MAXDBL', :ruby_read => false },
        {:name =>'d', :ctype=> :int, :pointer => true, :size_expr => '$num_nodes', :init_expr => '0', :ruby_read => false },

        # This is going to be loaded from nodes data
        { :name => 'locations', :ctype=>:double, :pointer => true, :size_expr => '20', :init_expr => '-1', :ruby_read => false },
        # This is going to be loaded from distance_rank data
        { :name => 'dr_max_rank', :ctype=>:int, :init_expr => '-1', :ruby_read => false },
        { :name => 'dr_closest_nodes', :ctype=>:int, :pointer => true, :size_expr => '20', :init_expr => '-1', :ruby_read => false },
      ],
      :init_params => [{:name=>'num_nodes',:ctype=>:int}]
    },

    { :name => 'priority_queue',
      :attributes => [
        {:name =>'pq_size', :ctype => :int, :init_expr => '0' },
        {:name =>'priorities', :ctype=> :double, :pointer => true, :size_expr => '$pq_size', :init_expr => 'PQ_MAXDBL', :ruby_read => false },
        {:name =>'payloads', :ctype=> :int, :pointer => true, :size_expr => '$pq_size', :init_expr => '-10000000', :ruby_read => false },

        {:name =>'heap_leftmost_child', :ctype=> :int, :pointer => true, :size_expr => '$pq_size', :init_expr => '-1', :ruby_read => false },
        {:name =>'heap_parent', :ctype=> :int, :pointer => true, :size_expr => '$pq_size', :init_expr => '-1', :ruby_read => false },
        {:name =>'heap_left_sibling', :ctype=> :int, :pointer => true, :size_expr => '$pq_size', :init_expr => '-1', :ruby_read => false },
        {:name =>'heap_right_sibling', :ctype=> :int, :pointer => true, :size_expr => '$pq_size', :init_expr => '-1', :ruby_read => false },

        {:name =>'root_candidates', :ctype=> :int, :pointer => true, :size_expr => '$pq_size', :init_expr => '-1', :ruby_read => false },
        {:name =>'first_pass_roots', :ctype=> :int, :pointer => true, :size_expr => '$pq_size', :init_expr => '-1', :ruby_read => false },

        {:name =>'heap_root', :ctype => :int, :init_expr => '-1' }
      ],
      :init_params => [{:name=>'pq_size',:ctype=>:int}]
    },
  ]
} )

# m.create_project(d)
## m.structs[0].write( d )
m.structs.last.write( d )
puts "TspKit: #{d}"
