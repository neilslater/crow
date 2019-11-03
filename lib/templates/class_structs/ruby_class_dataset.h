// ext/<%= lib_short_name %>/base/ruby_class_<%= short_name %>.h

#ifndef BASE_RUBY_CLASS_<%= short_name.upcase %>_H
#define BASE_RUBY_CLASS_<%= short_name.upcase %>_H

#include <ruby.h>
#include "narray.h"
#include "base/struct_<%= short_name %>.h"
#include "shared_vars.h"

void init_<%= short_name %>_class( );

VALUE <%= short_name %>_as_ruby_class( <%= struct_name %> *<%= short_name %> , VALUE klass );

VALUE <%= short_name %>_alloc( VALUE klass );

<%= struct_name %> *get_<%= short_name %>_struct( VALUE obj );

void assert_value_wraps_<%= short_name %>( VALUE obj );

#endif
