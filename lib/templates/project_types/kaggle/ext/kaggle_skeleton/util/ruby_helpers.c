// ext/kaggle_skeleton/util/ruby_helpers.c

#include "util/ruby_helpers.h"

// Hash lookup helper
VALUE ValAtSymbol(VALUE hash, const char* key) {
    return rb_hash_lookup(hash, ID2SYM( rb_intern(key) ) );
}
