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
void <%= short_name %>__init( <%= struct_name %> *<%= short_name %><% if init_params %>, <%= init_params %><% end %> ) {
  int i;
<% if any_narray? -%>
  struct NARRAY *narr;
<% end -%>

<% attributes.select(&:needs_alloc?).each do |attribute| -%>
  <%= short_name %>-><%= attribute.name %> = ALLOC_N( <%= attribute.cbase %>, <%= attribute.size_expr %> );
  for( i = 0; i < <%= attribute.size_expr %>; i++ ) {
    <%= short_name %>-><%= attribute.name %> = <%= attribute.init_expr %>;
  }

<% end -%>
  <%= short_name %>->input_item_shape[input_rank] = num_items;
  <%= short_name %>->narr_inputs = na_make_object( NA_SFLOAT, input_rank + 1, <%= short_name %>->input_item_shape, cNArray );
  GetNArray( <%= short_name %>->narr_inputs, narr );
  na_sfloat_set( narr->total, (float*) narr->ptr, (float) 0.0 );

  <%= short_name %>->num_items = num_items;

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
