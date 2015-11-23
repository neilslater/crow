// ext/kaggle_skeleton/ruby_module_ru_ne_ne.h

////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Declarations of narray helper functions
//

#ifndef RUBY_MODULE_FACTORY_ELF_H
#define RUBY_MODULE_FACTORY_ELF_H

#include <ruby.h>
#include "narray.h"
#include "core_narray.h"
#include "shared_vars.h"
#include "shared_helpers.h"
#include "mt.h"
<% structs.each do |s| -%>
#include "ruby_class_<%= s.short_name %>.h"
<% end -%>

void init_module_kaggle_skeleton();

#endif
