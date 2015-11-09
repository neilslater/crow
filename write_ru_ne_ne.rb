require 'crow'
m = Crow::LibDef.new( 'ru_ne_ne', {
  :structs => [
    { :name => 'trainer_bp_layer', :struct_name => 'TrainerBPLayer', :rb_class_name => 'Trainer_BPLayer',
      :attributes => [
        {:name =>'num_inputs', :ctype => :int, :init_expr => '$num_inputs' },
        {:name =>'num_outputs', :ctype => :int, :init_expr => '$num_outputs'},

        {:name =>'narr_de_dz', :ruby_name => 'de_dz', :ctype=>:NARRAY_FLOAT, :ptr_cache => 'de_dz', :rank_expr => '1', :shape_var => 'de_dz_shape', :shape_exprs => [ '$num_outputs' ] },
        {:name =>'narr_de_da', :ruby_name => 'de_da', :ctype=>:NARRAY_FLOAT, :ptr_cache => 'de_da', :rank_expr => '1', :shape_var => 'de_da_shape', :shape_exprs => [ '$num_inputs + 1' ] },
        {:name =>'narr_de_dw', :ruby_name => 'de_dw', :ctype=>:NARRAY_FLOAT, :ptr_cache => 'de_dw', :rank_expr => '2', :shape_var => 'de_dw_shape', :shape_exprs => [ '$num_inputs + 1', '$num_outputs' ] },
        {:name =>'narr_de_dw_momentum', :ruby_name => 'de_dw_momentum', :ctype=>:NARRAY_FLOAT, :ptr_cache => 'de_dw_momentum', :rank_expr => '2', :shape_expr => 'trainer_bp_layer->de_dw_shape' },
        {:name =>'narr_de_dw_rmsprop', :ruby_name => 'de_dw_rmsprop', :ctype=>:NARRAY_FLOAT, :ptr_cache => 'de_dw_rmsprop', :rank_expr => '2', :shape_expr => 'trainer_bp_layer->de_dw_shape' },

        {:name =>'learning_rate', :ctype => :float, :default => '0.01', :ruby_write => true },
        {:name =>'smoothing_type', :ctype => :int, :default => '0' }, # Technically it's an enum
        {:name =>'smoothing_rate', :ctype => :float, :default => '0.9', :ruby_write => true },

        {:name =>'max_norm', :ctype => :float, :default => '0.0', :ruby_write => true  },
        {:name =>'weight_decay', :ctype => :float, :default => '0.0', :ruby_write => true  }
        ],
      :init_params => [{:name=>'num_inputs',:ctype=>:int}, {:name=>'num_outputs',:ctype=>:int}]
    },

    { :name => 'gd_sgd', :struct_name => 'GradientDescent_SGD', :rb_class_name => 'GradientDescent_SGD',
      :attributes => [
        {:name =>'num_params', :ctype => :int, :init_expr => '$num_params' },
      ],
      :init_params => [{:name=>'num_params',:ctype=>:int}]
    },

    { :name => 'gd_nag', :struct_name => 'GradientDescent_NAG', :rb_class_name => 'GradientDescent_NAG',
      :attributes => [
        {:name =>'num_params', :ctype => :int, :init_expr => '$num_params' },
        {:name =>'momentum', :ctype => :float, :default => '0.01', :init_expr => '$momentum', :ruby_write => true },
        {:name =>'narr_weight_velocity', :ruby_name => 'weight_velocity', :ctype=>:NARRAY_FLOAT, :ptr_cache => 'weight_velocity', :rank_expr => '1', :shape_expr => '{$num_params}' }
      ],
      :init_params => [{:name=>'num_params',:ctype=>:int},{:name=>'momentum',:ctype=>:float}]
    },

    { :name => 'gd_rmsprop', :struct_name => 'GradientDescent_RMSProp', :rb_class_name => 'GradientDescent_RMSProp',
      :attributes => [
        {:name =>'num_params', :ctype => :int, :init_expr => '$num_params' },
        {:name =>'decay', :ctype => :float, :default => '0.9', :init_expr => '$decay', :ruby_write => true },
        {:name =>'epsilon', :ctype => :float, :default => '1.0e-6', :init_expr => '$epsilon', :ruby_write => true },
        {:name =>'narr_squared_de_dw', :ruby_name => 'squared_de_dw', :ctype=>:NARRAY_FLOAT, :ptr_cache => 'squared_de_dw', :rank_expr => '1', :shape_expr => '{$num_params}' },
        {:name =>'narr_average_squared_de_dw', :ruby_name => 'average_squared_de_dw', :ctype=>:NARRAY_FLOAT, :ptr_cache => 'average_squared_de_dw', :rank_expr => '1', :shape_expr => '{$num_params}' }
      ],
      :init_params => [{:name=>'num_params',:ctype=>:int},{:name=>'decay',:ctype=>:float},{:name=>'epsilon',:ctype=>:float}]
    },

    { :name => 'network',
      :attributes => [
        { :name =>'layers', :ctype => :VALUE, :init_expr => '$layers', :pointer => true },
        { :name =>'num_layers', :ctype => :int },
        { :name =>'num_inputs', :ctype => :int },
        { :name =>'num_outputs', :ctype => :int }
      ],
      :init_params => [{:name=>'layers',:ctype=>:VALUE,:pointer => true}]
    },

    { :name => 'mbgd', :struct_name => 'MBGD', :rb_class_name => 'Learn_MBGD',
      :attributes => [
        { :name =>'mbgd_layers', :ctype => :VALUE, :init_expr => '$layers', :pointer => true },
        { :name =>'num_layers', :ctype => :int },
        { :name =>'num_inputs', :ctype => :int },
        { :name =>'num_outputs', :ctype => :int }
      ],
      :init_params => [{:name=>'mbgd_layers',:ctype=>:VALUE,:pointer => true}]
    },

    { :name => 'network', :struct_name => 'Network', :rb_class_name => 'Network',
      :attributes => [
        { :name =>'nn_model', :ctype => :VALUE, :init_expr => '$nn_model' },
        { :name =>'learn', :ctype => :VALUE, :init_expr => '$learn' },
      ],
      :init_params => [{:name=>'nn_model',:ctype=>:VALUE},{:name=>'learn',:ctype=>:VALUE}]
    },
  ]
} )

m.structs[6].write( '/tmp' )
puts "Test 1: OK"
