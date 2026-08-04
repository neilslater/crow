// ext/kaggle_skeleton/util/narray_helper.c

#include "util/narray_helper.h"

// This is copied from na_array.c, with safety checks and temp vars removed
size_t na_quick_idxs_to_pos( int rank, const size_t *shape, const size_t *idxs ) {
  int i;
  size_t pos = 0;
  for ( i = 0; i < rank; i++ ) {
    pos = pos * shape[i] + idxs[i];
  }
  return pos;
}

// This is inverse of above
void na_quick_pos_to_idxs( int rank, const size_t *shape, size_t pos, size_t *idxs ) {
  int i;
  for ( i = rank - 1; i >= 0; i-- ) {
    idxs[ i ] = pos % shape[i];
    pos /= shape[i];
  }
  return;
}

// Init structure to single value
void na_sfloat_set( size_t size, float *ptr, float new_value ) {
  size_t i;
    for ( i = 0; i < size; i++ ) {
    ptr[ i ] = new_value;
  }
  return;
}
