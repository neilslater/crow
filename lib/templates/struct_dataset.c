// ext/ru_ne_ne/struct_<%= short_name %>.c

#include "struct_<%= short_name %>.h"

//////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Definitions of OO-style functions for manipulating <%= struct_name %> structs
//

<%= struct_name %> *<%= short_name %>__create() {
  <%= struct_name %> *<%= short_name %>;
  <%= short_name %> = xmalloc( sizeof(<%= struct_name %>) );
  <%= short_name %>->narr_inputs = Qnil;
  <%= short_name %>->input_item_shape = NULL;
  <%= short_name %>->num_items = 0;
  return <%= short_name %>;
}

void <%= short_name %>__init( <%= struct_name %> *<%= short_name %>, int input_rank, int *input_shape, int num_items ) {
  int i, size, *pos;
  struct NARRAY *narr;

  <%= short_name %>->input_item_shape = ALLOC_N( int, input_rank + 1);
  size = 1;
  for( i = 0; i < input_rank; i++ ) {
    <%= short_name %>->input_item_shape[i] = input_shape[i];
    size *= input_shape[i];
  }
  <%= short_name %>->input_item_shape[input_rank] = num_items;
  <%= short_name %>->narr_inputs = na_make_object( NA_SFLOAT, input_rank + 1, <%= short_name %>->input_item_shape, cNArray );
  GetNArray( <%= short_name %>->narr_inputs, narr );
  na_sfloat_set( narr->total, (float*) narr->ptr, (float) 0.0 );

  <%= short_name %>->num_items = num_items;

  return;
}

void <%= short_name %>__destroy( <%= struct_name %> *<%= short_name %> ) {
  xfree( <%= short_name %>->input_item_shape );
  xfree( <%= short_name %> );
  return;
}

void <%= short_name %>__gc_mark( <%= struct_name %> *<%= short_name %> ) {
  rb_gc_mark( <%= short_name %>->narr_inputs );
  return;
}
