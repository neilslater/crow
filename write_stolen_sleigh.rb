require 'crow'

d = '/Users/neilslater/personal/kaggle/stolen_sleigh/ext/stolen_sleigh'

m = Crow::LibDef.new( 'stolen_sleigh', {
  :structs => [
    { :name => 'input',
      :attributes => [
        {:name =>'narr_gifts', :ruby_name => 'gifts', :ctype=>:NARRAY_DOUBLE, :ptr_cache => 'gifts', :rank_expr => '2', :shape_var => 'gifts_shape', :shape_exprs => [ '4', '100000' ] },
        ],
      :init_params => []
    },

    { :name => 'solution',
      :attributes => [
        {:name =>'narr_items', :ruby_name => 'items', :ctype=>:NARRAY_INT_32, :ptr_cache => 'items', :rank_expr => '2', :shape_var => 'items_shape', :shape_exprs => [ '2', '100000' ] },
      ],
      :init_params => []
    },

    { :name => 'trip',
      :attributes => [
        {:name =>'narr_gifts', :ruby_name => 'gifts', :ctype=>:NARRAY_INT_32, :ptr_cache => 'gifts', :rank_expr => '1', :shape_var => 'gifts_shape', :shape_exprs => [ '$num_gifts' ] },
      ],
      :init_params => [{:name=>'num_gifts',:ctype=>:int}]
    },

    { :name => 'trip_collection',
      :attributes => [
        {:name =>'num_trips', :ctype=> :int },
        {:name =>'trips', :ctype=> :int, :pointer => true }, # Not actually a char*
      ],
      :init_params => []
    },

  ]
} )

m.structs.last.write( d )
puts "StolenSleigh: #{d}"
