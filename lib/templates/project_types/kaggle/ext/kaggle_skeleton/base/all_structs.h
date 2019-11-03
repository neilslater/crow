// ext/kaggle_skeleton/base/all_structs.h

#ifndef BASE_ALL_STRUCTS_H
#define BASE_ALL_STRUCTS_H

<% structs.each do |s| -%>
#include "base/struct_<%= s.short_name %>.h"
<% end -%>

#endif
