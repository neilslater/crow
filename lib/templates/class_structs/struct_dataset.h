// ext/<%= lib_short_name %>/base/struct_<%= short_name %>.h
#ifndef BASE_STRUCT_<%= short_name.upcase %>_H
#define BASE_STRUCT_<%= short_name.upcase %>_H
#include <ruby.h>
#include "util/ruby_helpers.h"
#include <numo/narray.h>
#include <numo/intern.h>
#include <stdint.h>
#include <limits.h>
#include <string.h>

typedef struct _<%= short_name %>_raw {
<% attributes.each do |attribute| -%>
  <%= attribute.declare %>
<% end -%>
  int crow_state; /* 0 EMPTY, 1 BUILDING, 2 READY; private generated bookkeeping */
<% alloc_attributes.each do |attribute| -%>
  size_t crow_extent_<%= attribute.name %>;
<% end -%>
<% narray_attributes.each do |attribute| -%>
  size_t crow_shape_<%= attribute.name %>[<%= attribute.init.normalized_shapes.length %>];
<% end -%>
} <%= struct_name %>;

<%= struct_name %> *<%= short_name %>__create(void);
void <%= short_name %>__init(<%= struct_name %> *<%= short_name %><% init_params.each do |p| %>, <%= p.as_param %><% end %>);
void <%= short_name %>__initialize_ruby(<%= struct_name %> *item, VALUE receiver, const VALUE *args);
void <%= short_name %>__restore(<%= struct_name %> *item, VALUE receiver, VALUE hash);
void <%= short_name %>__copy_ruby(<%= struct_name %> *copy, <%= struct_name %> *orig, VALUE receiver);
void <%= short_name %>__require_ready(<%= struct_name %> *item);
void <%= short_name %>__destroy(<%= struct_name %> *item);
void <%= short_name %>__gc_mark(<%= struct_name %> *item);
void <%= short_name %>__deep_copy(<%= struct_name %> *copy, <%= struct_name %> *orig);
<%= struct_name %> *<%= short_name %>__clone(<%= struct_name %> *orig);
<% narray_attributes.each do |a| -%>
narray_t *<%= a.narray_fn_name %>(<%= struct_name %> *item);
size_t *<%= a.shape_fn_name %>(<%= struct_name %> *item);
<%= a.item_ctype %> *<%= a.ptr_fn_name %>(<%= struct_name %> *item);
size_t <%= a.size_fn_name %>(<%= struct_name %> *item);
int <%= a.rank_fn_name %>(<%= struct_name %> *item);
<% end -%>
#endif
