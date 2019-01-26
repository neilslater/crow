// ext/<%= lib_short_name %>/ruby_class_<%= short_name %>.c

#include "ruby_class_<%= short_name %>.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Ruby bindings for training data arrays - the deeper implementation is in
//  struct_<%= short_name %>.c
//

VALUE <%= short_name %>_as_ruby_class( <%= struct_name %> *<%= short_name %> , VALUE klass ) {
  return Data_Wrap_Struct( klass, <%= short_name %>__gc_mark, <%= short_name %>__destroy, <%= short_name %> );
}

VALUE <%= short_name %>_alloc( VALUE klass ) {
  return <%= short_name %>_as_ruby_class( <%= short_name %>__create(), klass );
}

<%= struct_name %> *get_<%= short_name %>_struct( VALUE obj ) {
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

/* Document-class: <%= full_class_name_ruby %>
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
 * @return [<%= full_class_name_ruby %>] new ...
 */
VALUE <%= short_name %>_rbobject__initialize( VALUE self<% unless init_params.empty? %>, <%= init_params.map(&:as_rv_param).join(', ') %><% end %> ) {
  <%= struct_name %> *<%= short_name %> = get_<%= short_name %>_struct( self );

<% if needs_init? -%>
  <%= short_name %>__init( <%= short_name %><% unless init_params.empty? %>, <%= init_params.map(&:param_item_to_c).join(', ') %><% end %> );

<% end -%>
  return self;
}

/* @overload clone
 * When cloned, the returned <%= struct_name %> has deep copies of C data.
 * @return [<%= full_class_name_ruby %>] new
 */
VALUE <%= short_name %>_rbobject__initialize_copy( VALUE copy, VALUE orig ) {
  <%= struct_name %> *<%= short_name %>_copy;
  <%= struct_name %> *<%= short_name %>_orig;

  if (copy == orig) return copy;
  <%= short_name %>_orig = get_<%= short_name %>_struct( orig );
  <%= short_name %>_copy = get_<%= short_name %>_struct( copy );

  <%= short_name %>__deep_copy( <%= short_name %>_copy, <%= short_name %>_orig );

  return copy;
}

<% simple_attributes.each do |attribute| -%>
<% if attribute.ruby_read -%>
/* @!attribute <% if attribute.read_only? %>[r] <% end %><%= attribute.ruby_name %>
 * Description goes here
 * @return [<%= attribute.rdoc_type %>]
 */
VALUE <%= short_name %>_rbobject__get_<%= attribute.name %>( VALUE self ) {
  <%= struct_name %> *<%= short_name %> = get_<%= short_name %>_struct( self );
  return <%= attribute.struct_item_to_ruby %>;
}

<% end -%>
<% if attribute.ruby_write -%>
VALUE <%= short_name %>_rbobject__set_<%= attribute.name %>( VALUE self, VALUE <%= attribute.rv_name %> ) {
  <%= struct_name %> *<%= short_name %> = get_<%= short_name %>_struct( self );
  <%= short_name %>-><%= attribute.name %> = <%= attribute.param_item_to_c %>;
  return <%= attribute.rv_name %>;
}

<% end -%>
<% end -%>
<% narray_attributes.each do |attribute| -%>
/* @!attribute <% if attribute.read_only? %>[r] <% end %><%= attribute.ruby_name %>
 * Description goes here
 * @return [<%= attribute.rdoc_type %>]
 */
VALUE <%= short_name %>_rbobject__get_<%= attribute.name %>( VALUE self ) {
  <%= struct_name %> *<%= short_name %> = get_<%= short_name %>_struct( self );
  return <%= attribute.struct_item_to_ruby %>;
}

<% end -%>
<% alloc_attributes.each do |attribute| -%>
<% if attribute.ruby_read -%>
/* @!attribute <% if attribute.read_only? %>[r] <% end %><%= attribute.ruby_name %>
 * Description goes here
 * @return [<%= attribute.rdoc_type %>]
 */
VALUE <%= short_name %>_rbobject__get_<%= attribute.name %>( VALUE self ) {
  int i, s;
  volatile VALUE rv_ary_<%= attribute.name %>;
  <%= struct_name %> *<%= short_name %> = get_<%= short_name %>_struct( self );

  s = <%= attribute.size_expr_c %>;
  rv_ary_<%= attribute.name %> = rb_ary_new2( s );
  for( i = 0; i < s; i++ ) {
    rb_ary_store( rv_ary_<%= attribute.name %>, i,  <%= attribute.array_item_to_ruby_converter %>( <%= short_name %>-><%= attribute.name %>[i] ) );
  }

  return rv_ary_<%= attribute.name %>;
}

<% end -%>
<% if attribute.ruby_write -%>
VALUE <%= short_name %>_rbobject__set_<%= attribute.name %>( VALUE self, VALUE <%= attribute.rv_name %> ) {
  int i;
  <%= struct_name %> *<%= short_name %> = get_<%= short_name %>_struct( self );
  // TODO: Implement array writing routine
}

<% end -%>
<% end -%>
////////////////////////////////////////////////////////////////////////////////////////////////////

void init_<%= short_name %>_class( ) {
  // <%= struct_name %> instantiation and class methods
  rb_define_alloc_func( <%= full_class_name %>, <%= short_name %>_alloc );
  rb_define_method( <%= full_class_name %>, "initialize", <%= short_name %>_rbobject__initialize, <%= init_params.count %> );
  rb_define_method( <%= full_class_name %>, "initialize_copy", <%= short_name %>_rbobject__initialize_copy, 1 );

  // <%= struct_name %> attributes
<% attributes.each do |attribute| -%>
<% if attribute.ruby_read -%>
  rb_define_method( <%= full_class_name %>, "<%= attribute.ruby_name %>", <%= short_name %>_rbobject__get_<%= attribute.name %>, 0 );
<% end -%>
<% if attribute.ruby_write -%>
  rb_define_method( <%= full_class_name %>, "<%= attribute.ruby_name %>=", <%= short_name %>_rbobject__set_<%= attribute.name %>, 1 );
<% end -%>
<% end -%>
}
