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
  <%= short_name %>-><%= attribute.name %> = <%= attribute.default %>;
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
  <%= short_name %>-><%= attribute.name %> = na_make_object( <%= attribute.narray_enum_type %>, <%= attribute.rank_expr %>, <%= attribute.shape_expr %>, cNArray );
  GetNArray( <%= short_name %>-><%= attribute.name %>, narr );
  <%= attribute.name %>_ptr = (<%= attribute.item_ctype %>*) narr->ptr;
  for( i = 0; i < narr->total; i++ ) {
    <%= attribute.name %>_ptr[i] = <%= attribute.init_expr_c %>;
  }

<% end -%>
  return;
}

<% end -%>
void <%= short_name %>__destroy( <%= struct_name %> *<%= short_name %> ) {
<% attributes.select(&:needs_alloc?).each do |attribute| -%>
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
