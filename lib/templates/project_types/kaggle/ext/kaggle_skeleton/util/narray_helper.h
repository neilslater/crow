// ext/kaggle_skeleton/util/narray_helper.h

////////////////////////////////////////////////////////////////////////////////////////////////
//
// Declarations of narray helper functions
//

#ifndef UTIL_NARRAY_HELPER_H
#define UTIL_NARRAY_HELPER_H

#include <ruby.h>
#include <stddef.h>

// This is copied from na_array.c, with safety checks and temp vars removed
size_t na_quick_idxs_to_pos( int rank, const size_t *shape, const size_t *idxs );

// This is inverse of above
void na_quick_pos_to_idxs( int rank, const size_t *shape, size_t pos, size_t *idxs );

void na_sfloat_set( size_t size, float *ptr, float new_value );

#endif
