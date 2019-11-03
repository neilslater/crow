// ext/<%= lib_short_name %>/ruby/class_<%= short_name %>.h

#ifndef RUBY_CLASS_<%= short_name.upcase %>_H
#define RUBY_CLASS_<%= short_name.upcase %>_H

#include "util/narray_helper.h"
#include "util/ruby_helpers.h"
#include "util/mt.h"
#include "base/shared_vars.h"
<% parent_lib.structs.each do |s| -%>
#include "base/ruby_class_<%= s.short_name %>.h"
<% if s.short_name != short_name -%>
#include "ruby/class_<%= s.short_name %>.h"
<% end -%>
<% end -%>
#include "lib/<%= short_name %>.h"

void init_class_<%= short_name %>_ext();

#endif
