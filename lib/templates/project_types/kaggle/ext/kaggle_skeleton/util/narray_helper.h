// ext/kaggle_skeleton/util/narray_helper.h

////////////////////////////////////////////////////////////////////////////////////////////////
//
// Declarations of narray helper functions
//

#ifndef UTIL_NARRAY_HELPER_H
#define UTIL_NARRAY_HELPER_H

#include <ruby.h>
#include "narray.h"

// This is copied from na_array.c, with safety checks and temp vars removed
int na_quick_idxs_to_pos( int rank, int *shape, int *idxs );

// This is inverse of above
void na_quick_pos_to_idxs( int rank, int *shape, int pos, int *idxs );

void na_sfloat_set( int size, float *idxs, float new_value );

#endif
