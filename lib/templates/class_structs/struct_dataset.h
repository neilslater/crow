// ext/<%= lib_short_name %>/base/struct_<%= short_name %>.h

//////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Definition for <%= struct_name %> and declarations for its memory management
//

#ifndef BASE_STRUCT_<%= short_name.upcase %>_H
#define BASE_STRUCT_<%= short_name.upcase %>_H

#include <ruby.h>
#include "narray.h"

typedef struct _<%= short_name %>_raw {
<% attributes.each do |attribute| -%>
  <%= attribute.declare %>
<% end -%>
  } <%= struct_name %>;

<%= struct_name %> *<%= short_name %>__create();

<% if needs_init? -%>
void <%= short_name %>__init( <%= struct_name %> *<%= short_name %><% unless init_params.empty? %>, <%= init_params.map(&:as_param).join(', ') %><% end %> );

<% end -%>
<% narray_attributes.each do |attribute| -%>
struct NARRAY * <%= attribute.narray_fn_name %>( <%= struct_name %> *<%= short_name %> );

int * <%= attribute.shape_fn_name %>( <%= struct_name %> *<%= short_name %> );

<%= attribute.item_ctype %> * <%= attribute.ptr_fn_name %>( <%= struct_name %> *<%= short_name %> );

int <%= attribute.size_fn_name %>( <%= struct_name %> *<%= short_name %> );

int <%= attribute.rank_fn_name %>( <%= struct_name %> *<%= short_name %> );

<% end -%>
void <%= short_name %>__destroy( <%= struct_name %> *<%= short_name %> );

void <%= short_name %>__gc_mark( <%= struct_name %> *<%= short_name %> );

void <%= short_name %>__deep_copy( <%= struct_name %> *<%= short_name %>_copy, <%= struct_name %> *<%= short_name %>_orig );

<%= struct_name %> * <%= short_name %>__clone( <%= struct_name %> *<%= short_name %>_orig );

#endif
