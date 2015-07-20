// ext/<%= lib_short_name %>/struct_<%= short_name %>.h

//////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Definition for <%= struct_name %> and declarations for its memory management
//

#ifndef STRUCT_<%= short_name.upcase %>_H
#define STRUCT_<%= short_name.upcase %>_H

#include <ruby.h>
#include "narray.h"

typedef struct _<%= short_name %>_raw {
<% attributes.each do |attribute| -%>
  <%= attribute.declare %>
<% end -%>
  } <%= struct_name %>;

<%= struct_name %> *<%= short_name %>__create();

<% if needs_init? -%>
void <%= short_name %>__init( <%= struct_name %> *<%= short_name %><% if init_params %>, <%= init_params %><% end %> );

<% end -%>
void <%= short_name %>__destroy( <%= struct_name %> *<%= short_name %> );

void <%= short_name %>__gc_mark( <%= struct_name %> *<%= short_name %> );

#endif
