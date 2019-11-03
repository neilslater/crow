// ext/kaggle_skeleton/base/shared_vars.h

#ifndef BASE_SHARED_VARS_H
#define BASE_SHARED_VARS_H

extern VALUE KaggleSkeleton;
<% structs.each do |s| -%>
extern VALUE <%= s.full_class_name %>;
<% end -%>

#endif
