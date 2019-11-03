// ext/kaggle_skeleton/ruby_module_ru_ne_ne.h

////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Declarations of narray helper functions
//

#ifndef RUBY_MODULE_FACTORY_ELF_H
#define RUBY_MODULE_FACTORY_ELF_H

#include <ruby.h>
#include "narray.h"
#include "util/narray_helper.h"
#include "shared_vars.h"
#include "shared_helpers.h"
#include "util/mt.h"
<% structs.each do |s| -%>
#include "base/ruby_class_<%= s.short_name %>.h"
<% end -%>

void init_module_kaggle_skeleton();

#endif
