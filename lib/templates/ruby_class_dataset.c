// ext/<%= lib_short_name %>/ruby_class_<%= short_name %>.c

#include "ruby_class_<%= short_name %>.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Ruby bindings for training data arrays - the deeper implementation is in
//  struct_<%= short_name %>.c
//

inline VALUE <%= short_name %>_as_ruby_class( <%= struct_name %> *<%= short_name %> , VALUE klass ) {
  return Data_Wrap_Struct( klass, <%= short_name %>__gc_mark, <%= short_name %>__destroy, <%= short_name %> );
}

VALUE <%= short_name %>_alloc(VALUE klass) {
  return <%= short_name %>_as_ruby_class( <%= short_name %>__create(), klass );
}

inline <%= struct_name %> *get_<%= short_name %>_struct( VALUE obj ) {
  <%= struct_name %> *<%= short_name %>;
  Data_Get_Struct( obj, <%= struct_name %>, <%= short_name %> );
  return <%= short_name %>;
}

void assert_value_wraps_<%= short_name %>( VALUE obj ) {
  if ( TYPE(obj) != T_DATA ||
      RDATA(obj)->dfree != (RUBY_DATA_FUNC)<%= short_name %>__destroy) {
    rb_raise( rb_eTypeError, "Expected a <%= struct_name %> object, but got something else" );
  }
}

/* Document-class:  <%= lib_module_name %>::<%= struct_name %>
 *
 */

////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Network method definitions
//

/* @overload initialize( )
 * Creates a new network and initializes the weights in all layers.
 * @param [NArray] inputs size of input array for first layer
 * @param [NArray] targets sizes of output arrays for each hidden layer
 * @return [<%= lib_module_name %>::<%= struct_name %>] new network consisting of new layers, with random weights
 */
VALUE <%= short_name %>_class_initialize( VALUE self ) {
  <%= struct_name %> *<%= short_name %> = get_<%= short_name %>_struct( self );

<% if needs_init? -%>
  <%= short_name %>__init( <%= short_name %>, 1, {10} );

<% end -%>
  return self;
}

/* @overload clone
 * When cloned, the returned <%= struct_name %> has deep copies of inputs and outputs,
 * @return [<%= lib_module_name %>::<%= struct_name %>] new training data with identical items to caller.
 */
VALUE <%= short_name %>_class_initialize_copy( VALUE copy, VALUE orig ) {
  <%= struct_name %> *<%= short_name %>_copy;
  <%= struct_name %> *<%= short_name %>_orig;

  if (copy == orig) return copy;
  <%= short_name %>_orig = get_<%= short_name %>_struct( orig );
  <%= short_name %>_copy = get_<%= short_name %>_struct( copy );

  <%= short_name %>_copy->num_items = <%= short_name %>_orig->num_items;
  <%= short_name %>_copy->narr_inputs = na_clone( <%= short_name %>_orig->narr_inputs );

  return copy;
}

/* @!attribute [r] inputs
 * The inputs array.
 * @return [NArray<sfloat>]
 */
VALUE <%= short_name %>_object_inputs( VALUE self ) {
  <%= struct_name %> *<%= short_name %> = get_<%= short_name %>_struct( self );
  return <%= short_name %>->narr_inputs;
}

/* @!attribute [r] num_items
 * The number of training items.
 * @return [Integer]
 */
VALUE <%= short_name %>_object_num_items( VALUE self ) {
  <%= struct_name %> *<%= short_name %> = get_<%= short_name %>_struct( self );
  return INT2NUM( <%= short_name %>->num_items );
}

////////////////////////////////////////////////////////////////////////////////////////////////////

void init_<%= short_name %>_class( ) {
  // <%= struct_name %> instantiation and class methods
  rb_define_alloc_func( <%= lib_module_name %>_<%= struct_name %>, <%= short_name %>_alloc );
  rb_define_method( <%= lib_module_name %>_<%= struct_name %>, "initialize", <%= short_name %>_class_initialize, 0 );
  rb_define_method( <%= lib_module_name %>_<%= struct_name %>, "initialize_copy", <%= short_name %>_class_initialize_copy, 1 );

  // <%= struct_name %> attributes
  rb_define_method( <%= lib_module_name %>_<%= struct_name %>, "inputs", <%= short_name %>_object_inputs, 0 );
  rb_define_method( <%= lib_module_name %>_<%= struct_name %>, "num_items", <%= short_name %>_object_num_items, 0 );
}
