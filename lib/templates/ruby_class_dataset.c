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

/* @overload initialize( <%= init_params.map(&:name).join(', ') %> )
 * Creates a new ...
<% init_params.each do |ip| -%>
 * @param [<%= ip.rdoc_type %>] <%= ip.name %> ...
<% end -%>
 * @return [<%= lib_module_name %>::<%= struct_name %>] new ...
 */
VALUE <%= short_name %>_class_initialize( VALUE self<% unless init_params.empty? %>, <%= init_params.map(&:as_rv_param).join(', ') %><% end %> ) {
  <%= struct_name %> *<%= short_name %> = get_<%= short_name %>_struct( self );

<% if needs_init? -%>
  <%= short_name %>__init( <%= short_name %><% unless init_params.empty? %>, <%= init_params.map(&:param_item_to_c).join(', ') %><% end %> );

<% end -%>
  return self;
}

/* @overload clone
 * When cloned, the returned <%= struct_name %> has deep copies of C data.
 * @return [<%= lib_module_name %>::<%= struct_name %>] new
 */
VALUE <%= short_name %>_class_initialize_copy( VALUE copy, VALUE orig ) {
  <%= struct_name %> *<%= short_name %>_copy;
  <%= struct_name %> *<%= short_name %>_orig;

  if (copy == orig) return copy;
  <%= short_name %>_orig = get_<%= short_name %>_struct( orig );
  <%= short_name %>_copy = get_<%= short_name %>_struct( copy );

<% simple_attributes.each do |attribute| -%>
  <%= short_name %>_copy-><%= attribute.name %> = <%= short_name %>_orig-><%= attribute.name %>;
<% end -%>

<% narray_attributes.each do |attribute| -%>
  <%= short_name %>_copy-><%= attribute.name %> = na_clone( <%= short_name %>_orig-><%= attribute.name %> );
<% end -%>
<% init_attributes.each do |attribute| -%>

  <%= short_name %>_copy-><%= attribute.name %> = ALLOC_N( <%= attribute.cbase %>, <%= attribute.size_expr %> );
  memcpy( <%= short_name %>_copy-><%= attribute.name %>, <%= short_name %>_orig-><%= attribute.name %>, ( <%= attribute.size_expr %> ) * sizeof(<%= attribute.cbase %>) );
<% end -%>

  return copy;
}

<% simple_attributes.each do |attribute| -%>
/* @!attribute [r] <%= attribute.name %>
 * Description goes here
 * @return [<%= attribute.rdoc_type %>]
 */
VALUE <%= short_name %>_object_<%= attribute.name %>( VALUE self ) {
  <%= struct_name %> *<%= short_name %> = get_<%= short_name %>_struct( self );
  return <%= attribute.struct_item_to_ruby %>;
}

<% end -%>
<% narray_attributes.each do |attribute| -%>
/* @!attribute [r] <%= attribute.name %>
 * Description goes here
 * @return [<%= attribute.rdoc_type %>]
 */
VALUE <%= short_name %>_object_<%= attribute.name %>( VALUE self ) {
  <%= struct_name %> *<%= short_name %> = get_<%= short_name %>_struct( self );
  return <%= attribute.struct_item_to_ruby %>;
}

<% end -%>

////////////////////////////////////////////////////////////////////////////////////////////////////

void init_<%= short_name %>_class( ) {
  // <%= struct_name %> instantiation and class methods
  rb_define_alloc_func( <%= lib_module_name %>_<%= struct_name %>, <%= short_name %>_alloc );
  rb_define_method( <%= lib_module_name %>_<%= struct_name %>, "initialize", <%= short_name %>_class_initialize, 0 );
  rb_define_method( <%= lib_module_name %>_<%= struct_name %>, "initialize_copy", <%= short_name %>_class_initialize_copy, 1 );

  // <%= struct_name %> attributes
<% attributes.each do |attribute| -%>
  rb_define_method( <%= lib_module_name %>_<%= struct_name %>, "<%= attribute.name %>", <%= short_name %>_object_<%= attribute.name %>, 0 );
<% end -%>
}
