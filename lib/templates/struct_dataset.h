// ext/con_ne_ne/struct_<%= short_name %>.h

//////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Declarations of OO-style functions for manipulating TrainingSet structs
//

#ifndef STRUCT_<%= short_name.upcase %>_H
#define STRUCT_<%= short_name.upcase %>_H

#include <ruby.h>
#include "narray.h"

typedef struct _<%= short_name %>_raw {
    int *input_item_shape;
    int num_items;
    VALUE narr_inputs;
  } <%= struct_name %>;

<%= struct_name %> *<%= short_name %>__create();

void <%= short_name %>__init( <%= struct_name %> *<%= short_name %>, int input_rank, int *input_shape, int num_items );

void <%= short_name %>__destroy( <%= struct_name %> *<%= short_name %> );

void <%= short_name %>__gc_mark( <%= struct_name %> *<%= short_name %> );

#endif
