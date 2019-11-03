// ext/kaggle_skeleton/base/ruby_module_kaggle_skeleton.h

////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Combines all base generated Ruby bindings
//

#ifndef BASE_RUBY_MODULE_H
#define BASE_RUBY_MODULE_H

#include <ruby.h>
#include "narray.h"
#include "util/narray_helper.h"
#include "util/ruby_helpers.h"
#include "util/mt.h"
#include "base/shared_vars.h"
<% structs.each do |s| -%>
#include "base/ruby_class_<%= s.short_name %>.h"
#include "ruby/class_<%= s.short_name %>.h"
<% end -%>

void init_base_module_kaggle_skeleton();

#endif
