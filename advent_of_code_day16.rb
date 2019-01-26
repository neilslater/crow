require 'crow'
m = Crow::LibDef.new( 'dancing', {
  :structs => [
    { :name => 'dancers',
      :attributes => [
        {:name=>'count', :ctype=>:int, :default => '0', :init_expr => '$n', :ruby_write => false },
        {:name=>'offset', :ctype=>:int, :default => '0', :init_expr => '0', :ruby_write => false },
        {:name=>'positions', :ctype=>:char, :pointer => true, :size_expr => '%count', :ruby_read => false },
        ],
      :init_params => [{:name=>'n', :ctype=>:int }]
    },
    { :name => 'dance',
      :attributes => [
        {:name=>'count', :ctype=>:int, :default => '0', :init_expr => '$n', :ruby_write => false },
        {:name=>'moves', :ctype=>:char, :pointer => true, :size_expr => '%count', :ruby_read => false},
        {:name=>'movedata_a', :ctype=>:char, :pointer => true, :size_expr => '%count', :ruby_read => false},
        {:name=>'movedata_b', :ctype=>:char, :pointer => true, :size_expr => '%count', :ruby_read => false}
        ],
      :init_params => [{:name=>'n', :ctype=>:int }]
    },
  ]
} )
m.create_project('/Users/neilslater/scraps/advent/day16')
puts "Test 1: OK"
