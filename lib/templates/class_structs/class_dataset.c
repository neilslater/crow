// ext/<%= lib_short_name %>/ruby/class_<%= short_name %>.c

#include "ruby/class_<%= short_name %>.h"

/* Example method
VALUE <%= short_name %>_rbobject__foo( VALUE self ) {
  <%= struct_name %> *<%= short_name %> = get_<%= short_name %>_struct( self );
  return INT2NUM( <%= short_name %>__count( <%= short_name %> ) );
}
*/

/* Document-class: <%= full_class_name_ruby %>
 *
 */

void init_class_<%= short_name %>_ext() {
  // Example:
  //   rb_define_method( <%= full_class_name %>, "foo", <%= short_name %>_rbobject__foo, 0 );
  return;
}
