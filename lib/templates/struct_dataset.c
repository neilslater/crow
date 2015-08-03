// ext/<%= lib_short_name %>/struct_<%= short_name %>.c

#include "struct_<%= short_name %>.h"

//////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Definitions for <%= struct_name %> memory management
//

<%= struct_name %> *<%= short_name %>__create() {
  <%= struct_name %> *<%= short_name %>;
  <%= short_name %> = xmalloc( sizeof(<%= struct_name %>) );
<% attributes.each do |attribute| -%>
<% if attribute.shape_var %>  <%= attribute.init_shape_var %>;
<% end -%>
  <%= short_name %>-><%= attribute.name %> = <%= attribute.default %>;
<% if attribute.ptr_cache %>  <%= attribute.init_ptr_cache %>;
<% end -%>
<% end -%>
  return <%= short_name %>;
}

<% if needs_init? -%>
void <%= short_name %>__init( <%= struct_name %> *<%= short_name %><% unless init_params.empty? %>, <%= init_params.map(&:as_param).join(', ') %><% end %> ) {
  int i;
<% if any_narray? -%>
  struct NARRAY *narr;
<% narray_attributes.each do |attribute| -%>
  <%= attribute.item_ctype %> *<%= attribute.name %>_ptr;
<% end -%>
<% end -%>

<% simple_attributes_with_init.each do |attribute| -%>
  <%= short_name %>-><%= attribute.name %> = <%= attribute.init_expr_c %>;

<% end -%>
<% alloc_attributes.each do |attribute| -%>
  <%= short_name %>-><%= attribute.name %> = ALLOC_N( <%= attribute.cbase %>, <%= attribute.size_expr_c %> );
  for( i = 0; i < <%= attribute.size_expr_c %>; i++ ) {
    <%= short_name %>-><%= attribute.name %>[i] = <%= attribute.init_expr_c %>;
  }

<% end -%>
<% narray_attributes.each do |attribute| -%>
<% if attribute.shape_var -%>
  <%= short_name %>-><%= attribute.shape_var %> = ALLOC_N( int, <%= attribute.rank_expr %> );
<% attribute.shape_exprs.each_with_index do |expr,n| -%>
  <%= short_name %>-><%= attribute.shape_var %>[<%= n %>] = <%= Expression.new( expr, attribute.parent_struct.attributes, attribute.parent_struct.init_params ).as_c_code( short_name ) %>;
<% end -%>
<% end -%>
  <%= short_name %>-><%= attribute.name %> = na_make_object( <%= attribute.narray_enum_type %>, <%= attribute.rank_expr %>, <%= attribute.shape_expr_c %>, cNArray );
  GetNArray( <%= short_name %>-><%= attribute.name %>, narr );
  <%= attribute.name %>_ptr = (<%= attribute.item_ctype %>*) narr->ptr;
  for( i = 0; i < narr->total; i++ ) {
    <%= attribute.name %>_ptr[i] = <%= attribute.init_expr_c %>;
  }
<% if attribute.ptr_cache %>  <%= attribute.set_ptr_cache %>;
<% end -%>

<% end -%>
  return;
}

<% end -%>
void <%= short_name %>__destroy( <%= struct_name %> *<%= short_name %> ) {
<% alloc_attributes.each do |attribute| -%>
  xfree( <%= short_name %>-><%= attribute.name %> );
<% end -%>
<% narray_attributes.select(&:shape_var).each do |attribute| -%>
  xfree( <%= short_name %>-><%= attribute.shape_var %> );
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
<% if narray_attributes.any? { |a| a.ptr_cache } -%>
  struct NARRAY *narr;

<% end -%>
<% simple_attributes.each do |attribute| -%>
  <%= short_name %>_copy-><%= attribute.name %> = <%= short_name %>_orig-><%= attribute.name %>;
<% end -%>

<% narray_attributes.each do |attribute| -%>
  <%= short_name %>_copy-><%= attribute.name %> = na_clone( <%= short_name %>_orig-><%= attribute.name %> );
<% if attribute.ptr_cache -%>
  GetNArray( <%= short_name %>_copy-><%= attribute.name %>, narr );
  <%= attribute.set_ptr_cache( short_name + "_copy" ) %>;
<% end -%>
<% if attribute.shape_var -%>
  <%= short_name %>_copy-><%= attribute.shape_var %> = ALLOC_N( int, <%= attribute.rank_expr %> );
  memcpy( <%= short_name %>_copy-><%= attribute.shape_var %>, <%= short_name %>_orig-><%= attribute.shape_var %>, <%= attribute.rank_expr %> * sizeof(int) );
<% end -%>

<% end -%>
<% alloc_attributes.each do |attribute| -%>
  <%= short_name %>_copy-><%= attribute.name %> = ALLOC_N( <%= attribute.cbase %>, <%= attribute.size_expr_c( short_name + "_copy" ) %> );
  memcpy( <%= short_name %>_copy-><%= attribute.name %>, <%= short_name %>_orig-><%= attribute.name %>, ( <%= attribute.size_expr_c %> ) * sizeof(<%= attribute.cbase %>) );

<% end -%>
  return;
}

<%= struct_name %> * <%= short_name %>__clone( <%= struct_name %> *<%= short_name %>_orig ) {
  <%= struct_name %> * <%= short_name %>_copy = <%= short_name %>__create();
  <%= short_name %>__deep_copy( <%= short_name %>_copy, <%= short_name %>_orig );
  return <%= short_name %>_copy;
}
