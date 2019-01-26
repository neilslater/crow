require 'crow'

d = '/Users/neilslater/personal/kaggle/santa2018/app/ext/santa_2018'

m = Crow::LibDef.new( 'santa_2018', {
  :structs => [
    { :name => 'cities',
      :attributes => [
        {:name =>'num_cities', :ctype => :int, :init_expr => '$num_cities' },
        {:name =>'narr_locations', :ruby_name => 'locations', :ctype=>:NARRAY_DOUBLE, :ptr_cache => 'locations', :rank_expr => '2', :shape_var => 'locations_shape', :shape_exprs => [ '2', '$num_cities' ] },
        {:name =>'narr_prime_cities', :ruby_name => 'prime_cities', :ctype=>:NARRAY_INT_16, :ptr_cache => 'prime_cities', :rank_expr => '1', :shape_var => 'prime_cities_shape', :shape_exprs => [ '$num_cities' ] },
        ],
      :init_params => [{:name=>'num_cities',:ctype=>:int}]
    },

    { :name => 'distance_rank',
      :attributes => [
        {:name =>'num_cities', :ctype => :int, :init_expr => '$num_cities' },
        {:name =>'max_rank', :ctype => :int, :init_expr => '$max_rank' },
        {:name =>'narr_closest_cities', :ruby_name => 'closest_cities', :ctype=>:NARRAY_INT_32, :ptr_cache => 'closest_cities', :rank_expr => '2', :shape_var => 'closest_cities_shape', :shape_exprs => [ '$max_rank', '$num_cities' ] },
        ],
      :init_params => [{:name=>'num_cities',:ctype=>:int}, {:name=>'max_rank',:ctype=>:int}]
    },

    { :name => 'solution',
      :attributes => [
        {:name =>'num_cities', :ctype => :int, :init_expr => '$num_cities' },
        {:name =>'narr_ids', :ruby_name => 'ids', :ctype=>:NARRAY_INT_32, :ptr_cache => 'ids', :rank_expr => '1', :shape_var => 'ids_shape', :shape_exprs => [ '$num_cities' ] },
        {:name =>'narr_city_idx', :ruby_name => 'city_idx', :ctype=>:NARRAY_INT_32, :ptr_cache => 'city_idx', :rank_expr => '1', :shape_var => 'city_idx_shape', :shape_exprs => [ '$num_cities' ] },
      ],
      :init_params => [{:name=>'num_cities',:ctype=>:int}]
    },

    { :name => 'solution_slice',
      :attributes => [
        {:name =>'slice_size', :ctype => :int, :init_expr => '$slice_size' },
        {:name =>'slice_offset', :ctype => :int, :init_expr => '$slice_offset' },

        # Re-create section of main city ids, usi
        {:name =>'narr_slice_ids', :ruby_name => 'slice_ids', :ctype=>:NARRAY_INT_32, :ptr_cache => 'slice_ids', :rank_expr => '1', :shape_var => 'slice_ids_shape', :shape_exprs => [ '$slice_size' ] },
        {:name =>'narr_slice_idx', :ruby_name => 'slice_idx', :ctype=>:NARRAY_INT_32, :ptr_cache => 'slice_idx', :rank_expr => '1', :shape_var => 'slice_idx_shape', :shape_exprs => [ '$slice_size' ] },

        # How to convert back
        {:name =>'narr_slice_to_city_ids', :ruby_name => 'slice_to_city_ids', :ctype=>:NARRAY_INT_32, :ptr_cache => 'slice_to_city_ids', :rank_expr => '1', :shape_var => 'slice_to_city_ids_shape', :shape_exprs => [ '$slice_size' ] },

        # Distance cache for fast calculations
        {:name =>'narr_distance_cache', :ruby_name => 'distance_cache', :ctype=>:NARRAY_DOUBLE, :ptr_cache => 'distance_cache', :rank_expr => '2', :shape_var => 'distance_cache_shape', :shape_exprs => [ '$slice_size', '$slice_size' ] },
      ],
      :init_params => [{:name=>'slice_size',:ctype=>:int}, {:name=>'slice_offset', :ctype=>:int}]
    },

    { :name => 'greedy_solver',
      :attributes => [
        {:name =>'num_cities', :ctype => :int, :init_expr => '$num_cities' },
        {:name =>'max_section_id', :ctype => :int, :init_expr => '0' },
        {:name =>'route_start', :ctype => :int, :init_expr => '-1', :ruby_read => false },
        {:name =>'count_links', :ctype => :int, :init_expr => '0', :ruby_read => false },
        {:name =>'route_link_left', :ctype=> :int, :pointer => true, :size_expr => '$num_cities', :init_expr => '-1', :ruby_read => false },
        {:name =>'route_link_right', :ctype=> :int, :pointer => true, :size_expr => '$num_cities', :init_expr => '-1', :ruby_read => false },
        {:name =>'path_section_id', :ctype=> :int, :pointer => true, :size_expr => '$num_cities', :init_expr => '-1', :ruby_read => false }
      ],
      :init_params => [{:name=>'num_cities',:ctype=>:int}]
    },

    { :name => 'kopt_solver',
      :attributes => [
        { :name =>'narr_k_dist', :ruby_name => 'k_dist', :ctype=>:NARRAY_INT_32, :ptr_cache => 'k_dist', :rank_expr => '1', :shape_var => 'k_dist_shape', :shape_exprs => [ '100' ] },
        { :name =>'temperature', :ctype => :double, :init_expr => '0.0', :ruby_write => true },
        { :name =>'locale_stdev', :ctype => :double, :init_expr => '2.0', :ruby_write => true },
        { :name =>'candidate_scheme', :ctype => :int, :init_expr => '0', :ruby_write => true },
        { :name =>'current_score', :ctype => :double, :init_expr => '0.0' },

        # For improved penalty-aware version later . . .
        { :name =>'penalty_aware', :ctype => :int, :init_expr => '0', :ruby_write => true },
        { :name =>'max_segment_size', :ctype => :int, :init_expr => '1000', :ruby_write => true },

        # Stats
        { :name =>'narr_num_candidates', :ruby_name => 'stats_num_candidates', :ctype=>:NARRAY_INT_32, :ptr_cache => 'stats_num_candidates', :rank_expr => '1', :shape_var => 'stats_num_candidates_shape', :shape_exprs => [ '7' ] },
        { :name =>'narr_num_too_large', :ruby_name => 'stats_num_too_large', :ctype=>:NARRAY_INT_32, :ptr_cache => 'stats_num_too_large', :rank_expr => '1', :shape_var => 'stats_num_too_large_shape', :shape_exprs => [ '7' ] },
        { :name =>'narr_num_rejected', :ruby_name => 'stats_num_rejected', :ctype=>:NARRAY_INT_32, :ptr_cache => 'stats_num_rejected', :rank_expr => '1', :shape_var => 'stats_num_rejected_shape', :shape_exprs => [ '7' ] },
        { :name =>'narr_num_accepted', :ruby_name => 'stats_num_accepted', :ctype=>:NARRAY_INT_32, :ptr_cache => 'stats_num_accepted', :rank_expr => '1', :shape_var => 'stats_num_accepted_shape', :shape_exprs => [ '7' ] },
        { :name =>'narr_total_delta', :ruby_name => 'stats_total_delta', :ctype=>:NARRAY_DOUBLE, :ptr_cache => 'stats_total_delta', :rank_expr => '1', :shape_var => 'stats_total_delta_shape', :shape_exprs => [ '7' ] },
      ],
      :init_params => []
    },

    { :name => 'heap_solver',
      :attributes => [
        { :name =>'segment_length', :ctype => :int, :init_expr => '0', :ruby_write => true },
        { :name =>'current_score', :ctype => :double, :init_expr => '0.0' },
        { :name =>'perm_offset', :ctype=> :int, :init_expr => '0', :ruby_read => false }, # Offset in main store
        { :name =>'perm', :ctype=> :int, :pointer => true, :size_expr => '20', :init_expr => '-1', :ruby_read => false },
        { :name =>'penalty_position', :ctype=> :int, :pointer => true, :size_expr => '20', :init_expr => '-1', :ruby_read => false },

        # These are going to be loaded from relevant shared data (needs to be fed solution plus current cities)
        { :name => 'path_length', :ctype=> :int, :init_expr => '0', :ruby_read => false },
        { :name => 'path', :ctype=> :int, :pointer => true, :size_expr => '20', :init_expr => '-1', :ruby_read => false },
        { :name => 'path_idx', :ctype=> :int, :pointer => true, :size_expr => '20', :init_expr => '-1', :ruby_read => false },
        { :name => 'locations', :ctype=>:double, :pointer => true, :size_expr => '20', :init_expr => '-1', :ruby_read => false },
        { :name => 'prime_cities', :ctype=>:int, :pointer => true, :size_expr => '20', :init_expr => '-1', :ruby_read => false }
      ],
      :init_params => []
    },

    { :name => 'one_tree', :short_name => 'ot',
      :attributes => [
        {:name =>'num_cities', :ctype => :int, :init_expr => '$num_cities' },
        {:name =>'narr_city_penalties', :ruby_name => 'city_penalties', :ctype=>:NARRAY_DOUBLE, :ptr_cache => 'city_penalties', :rank_expr => '1', :shape_var => 'city_penalties_shape', :shape_exprs => [ '$num_cities' ] },
        {:name =>'narr_city_ids', :ruby_name => 'city_ids', :ctype=>:NARRAY_INT_32, :ptr_cache => 'city_ids', :rank_expr => '1', :shape_var => 'city_ids_shape', :shape_exprs => [ '$num_cities + 1' ] },
        {:name =>'narr_parents', :ruby_name => 'parents', :ctype=>:NARRAY_INT_32, :ptr_cache => 'parents', :rank_expr => '1', :shape_var => 'parents_shape', :shape_exprs => [ '$num_cities + 1' ] },

        # These are buffers used to help build the tree
        {:name =>'q', :ctype=> :int, :pointer => true, :size_expr => '$num_cities', :init_expr => '1', :ruby_read => false },
        {:name =>'c', :ctype=> :double, :pointer => true, :size_expr => '$num_cities', :init_expr => '10000000.0', :ruby_read => false },
        {:name =>'d', :ctype=> :int, :pointer => true, :size_expr => '$num_cities', :init_expr => '0', :ruby_read => false },

        # This is going to be loaded from cities data
        { :name => 'locations', :ctype=>:double, :pointer => true, :size_expr => '20', :init_expr => '-1', :ruby_read => false },
        # This is going to be loaded from distance_rank data
        { :name => 'dr_max_rank', :ctype=>:int, :init_expr => '-1', :ruby_read => false },
        { :name => 'dr_closest_cities', :ctype=>:int, :pointer => true, :size_expr => '20', :init_expr => '-1', :ruby_read => false },
      ],
      :init_params => [{:name=>'num_cities',:ctype=>:int}]
    },

    { :name => 'priority_queue',
      :attributes => [
        {:name =>'pq_size', :ctype => :int, :init_expr => '0' },
        {:name =>'n_min', :ctype => :int, :init_expr => '0' },
        {:name =>'n_max', :ctype => :int, :init_expr => '-1' },
        {:name =>'ids', :ctype=> :int, :pointer => true, :size_expr => '$pq_size', :init_expr => '-10000000', :ruby_read => false },
        {:name =>'priorities', :ctype=> :double, :pointer => true, :size_expr => '$pq_size', :init_expr => '10000000.0', :ruby_read => false },
      ],
      :init_params => [{:name=>'pq_size',:ctype=>:int}]
    },
  ]
} )

# m.create_project(d)
# m.structs[0].write( d )
m.structs.last.write( d )
puts "Santa2018: #{d}"
