// ext/<%= lib_short_name %>/base/struct_<%= short_name %>.c

#include "base/struct_<%= short_name %>.h"

//////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Definitions for <%= struct_name %> memory management
//

<% narray_attributes.each do |attribute| -%>
narray_t * <%= attribute.narray_fn_name %>( <%= struct_name %> *<%= short_name %> ) {
  narray_t *narr;
  GetNArray( <%= short_name %>-><%= attribute.name %>, narr );
  return narr;
}

size_t * <%= attribute.shape_fn_name %>( <%= struct_name %> *<%= short_name %> ) {
  narray_t *narr;
  GetNArray( <%= short_name %>-><%= attribute.name %>, narr );
  return narr->shape;
}

<%= attribute.item_ctype %> * <%= attribute.ptr_fn_name %>( <%= struct_name %> *<%= short_name %> ) {
  return (<%= attribute.item_ctype %> *)na_get_pointer_for_read_write( <%= short_name %>-><%= attribute.name %> );
}

size_t <%= attribute.size_fn_name %>( <%= struct_name %> *<%= short_name %> ) {
  narray_t *narr;
  GetNArray( <%= short_name %>-><%= attribute.name %>, narr );
  return narr->size;
}

int <%= attribute.rank_fn_name %>( <%= struct_name %> *<%= short_name %> ) {
  narray_t *narr;
  GetNArray( <%= short_name %>-><%= attribute.name %>, narr );
  return narr->ndim;
}

<% end -%>
<%= struct_name %> *<%= short_name %>__create() {
  <%= struct_name %> *<%= short_name %>;
  <%= short_name %> = xmalloc( sizeof(<%= struct_name %>) );
<% attributes.each do |attribute| -%>
  <%= short_name %>-><%= attribute.name %> = <%= attribute.default %>;
<% end -%>
  return <%= short_name %>;
}

<% if needs_init? -%>
void <%= short_name %>__init( <%= struct_name %> *<%= short_name %><% unless init_params.empty? %>, <%= init_params.map(&:as_param).join(', ') %><% end %> ) {
<% if needs_init_iterators? -%>
  size_t i;
<% end -%>
<% narray_attributes.each do |attribute| -%>
  <%= attribute.declare_ptr_cache %>
  <%= attribute.declare_shape_var %>
<% end -%>

<% simple_attributes_with_init.each do |attribute| -%>
  <%= short_name %>-><%= attribute.name %> = <%= attribute.init_expr_c(init_context: true) %>;

<% end -%>
<% alloc_attributes.each do |attribute| -%>
  <%= short_name %>-><%= attribute.name %> = ALLOC_N( <%= attribute.cbase %>, <%= attribute.init.size_expr_c(init_context: true) %> );
  for( i = 0; i < <%= attribute.init.size_expr_c(init_context: true) %>; i++ ) {
    <%= short_name %>-><%= attribute.name %>[i] = <%= attribute.init_expr_c %>;
  }

<% end -%>
<% narray_attributes.each do |attribute| -%>
  <%= attribute.shape_tmp_var %> = ALLOC_N( size_t, <%= attribute.init.rank_expr %> );
<% attribute.init.shape_exprs.each_with_index do |expr,n| -%>
  <%= attribute.shape_tmp_var %>[<%= n %>] = <%= Crow::Expression.new( expr, attribute.parent_struct.attributes, attribute.parent_struct.init_params ).as_c_code( short_name ) %>;
<% end -%>
  <%= short_name %>-><%= attribute.name %> = nary_new( <%= attribute.narray_enum_type %>, <%= attribute.init.rank_expr %>, <%= attribute.init.shape_expr_c %> );
  <%= attribute.set_ptr_cache %>
  for( i = 0; i < <%= attribute.size_fn_name %>( <%= short_name %> ); i++ ) {
    <%= attribute.ptr_tmp_var %>[i] = <%= attribute.init_expr_c %>;
  }

<% end -%>

<% narray_attributes.each do |attribute| -%>
  xfree(<%= attribute.shape_tmp_var %>);
<% end -%>
  return;
}

<% end -%>
void <%= short_name %>__destroy( <%= struct_name %> *<%= short_name %> ) {
<% alloc_attributes.each do |attribute| -%>
  xfree( <%= short_name %>-><%= attribute.name %> );
<% end -%>
  xfree( <%= short_name %> );
  return;
}

void <%= short_name %>__gc_mark( <%= struct_name %> *<%= short_name %> ) {
<% attributes.select(&:needs_gc_mark?).each do |attribute| -%>
  rb_gc_mark( <%= short_name %>-><%= attribute.name %> );
<% end -%>
  return;
}

void <%= short_name %>__deep_copy( <%= struct_name %> *<%= short_name %>_copy, <%= struct_name %> *<%= short_name %>_orig ) {
<% simple_attributes.each do |attribute| -%>
  <%= short_name %>_copy-><%= attribute.name %> = <%= short_name %>_orig-><%= attribute.name %>;
<% end -%>

<% narray_attributes.each do |attribute| -%>
  <%= short_name %>_copy-><%= attribute.name %> = rb_funcall( <%= short_name %>_orig-><%= attribute.name %>, rb_intern("dup"), 0 );
<% end -%>

<% alloc_attributes.each do |attribute| -%>
  <%= short_name %>_copy-><%= attribute.name %> = ALLOC_N( <%= attribute.cbase %>, <%= attribute.init.size_expr_c( from: short_name + "_copy" ) %> );
  memcpy( <%= short_name %>_copy-><%= attribute.name %>, <%= short_name %>_orig-><%= attribute.name %>, ( <%= attribute.init.size_expr_c( from: short_name + "_copy" ) %> ) * sizeof(<%= attribute.cbase %>) );

<% end -%>
  return;
}

<%= struct_name %> * <%= short_name %>__clone( <%= struct_name %> *<%= short_name %>_orig ) {
  <%= struct_name %> * <%= short_name %>_copy = <%= short_name %>__create();
  <%= short_name %>__deep_copy( <%= short_name %>_copy, <%= short_name %>_orig );
  return <%= short_name %>_copy;
}
