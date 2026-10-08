// ext/<%= lib_short_name %>/base/ruby_class_<%= short_name %>.c
#include "base/ruby_class_<%= short_name %>.h"

typedef struct { VALUE klass; <%= struct_name %> *item; } <%= short_name %>__wrap_args;
static VALUE <%= short_name %>__wrap(VALUE opaque) {
  <%= short_name %>__wrap_args *args = (<%= short_name %>__wrap_args *)opaque;
  return Data_Wrap_Struct(args->klass, <%= short_name %>__gc_mark, <%= short_name %>__destroy, args->item);
}
VALUE <%= short_name %>_as_ruby_class(<%= struct_name %> *item, VALUE klass) {
  int state;
  VALUE roots[] = {<%= (attributes.select(&:needs_gc_mark?).map { |a| "item ? item->#{a.name} : Qnil" } + ['Qnil']).join(', ') %>};
  <%= short_name %>__wrap_args args = {klass, item};
  VALUE result = rb_protect(<%= short_name %>__wrap, (VALUE)&args, &state);
  for (size_t i = 0; i < sizeof(roots) / sizeof(VALUE); ++i) RB_GC_GUARD(roots[i]);
  if (state) { <%= short_name %>__destroy(item); rb_jump_tag(state); }
  return result;
}
VALUE <%= short_name %>_alloc(VALUE klass) {
  VALUE result = Data_Wrap_Struct(klass, <%= short_name %>__gc_mark, <%= short_name %>__destroy, NULL);
  DATA_PTR(result) = <%= short_name %>__create();
  return result;
}
void assert_value_wraps_<%= short_name %>(VALUE obj) {
  if (TYPE(obj) != T_DATA || RTYPEDDATA_P(obj) ||
      !rb_obj_is_kind_of(obj, <%= full_class_name %>) ||
      RDATA(obj)->dfree != (RUBY_DATA_FUNC)<%= short_name %>__destroy || !DATA_PTR(obj))
    rb_raise(rb_eTypeError, "Expected a compatible <%= struct_name %> object");
}
<%= struct_name %> *get_<%= short_name %>_struct(VALUE obj) {
  assert_value_wraps_<%= short_name %>(obj);
  return DATA_PTR(obj);
}

/* Document-class: <%= full_class_name_ruby %> */
VALUE <%= short_name %>_rbobject__initialize(VALUE self<% init_params.each do |p| %>, <%= p.as_rv_param %><% end %>) {
  rb_check_frozen(self);
  VALUE args[] = {<%= (init_params.map(&:rv_name) + ['Qnil']).join(', ') %>};
  <%= short_name %>__initialize_ruby(get_<%= short_name %>_struct(self), self, args);
  return self;
}
VALUE <%= short_name %>_rbobject__initialize_copy(VALUE copy, VALUE orig) {
  if (copy == orig) return copy;
  rb_obj_init_copy(copy, orig);
  <%= struct_name %> *source = get_<%= short_name %>_struct(orig);
  <%= short_name %>__copy_ruby(get_<%= short_name %>_struct(copy), source, copy);
  RB_GC_GUARD(orig);
  return copy;
}
VALUE <%= short_name %>_rbobject__to_h(VALUE self) {
  <%= struct_name %> *<%= short_name %> = get_<%= short_name %>_struct(self);
  <%= short_name %>__require_ready(<%= short_name %>);
  VALUE hash = rb_hash_new();
<% stored_attributes.each do |a| -%>
<% if a.narray? -%>
  <%= a.narray_fn_name %>(<%= short_name %>);
<% end -%>
  rb_hash_aset(hash, ID2SYM(rb_intern("<%= a.name %>")), <%= a.struct_item_to_ruby %>);
<% end -%>
  RB_GC_GUARD(self);
  return hash;
}
/* Stored-field snapshot restoration. <%= restoration_error ? "Unavailable: #{restoration_error}" : 'Residual buffers reset; NArrays materialize independent logical copies.' %> */
VALUE <%= short_name %>_rbclass__from_h(int argc, VALUE *argv, VALUE self) {
  VALUE hash;
  rb_scan_args(argc, argv, ":", &hash);
<% if restoration_error -%>
  rb_raise(rb_eArgError, "Restoration unsupported: %s", <%= restoration_error.inspect %>);
<% else -%>
  if (NIL_P(hash)) hash = rb_hash_new();
  VALUE result = <%= short_name %>_alloc(self);
  <%= short_name %>__restore(get_<%= short_name %>_struct(result), result, hash);
  RB_GC_GUARD(hash);
  return result;
<% end -%>
}

<% simple_attributes.each do |a| -%>
<% if a.ruby_read -%>
VALUE <%= short_name %>_rbobject__get_<%= a.name %>(VALUE self) {
  <%= struct_name %> *<%= short_name %> = get_<%= short_name %>_struct(self);
  <%= short_name %>__require_ready(<%= short_name %>);
  return <%= a.struct_item_to_ruby %>;
}
<% end -%>
<% if a.ruby_write -%>
VALUE <%= short_name %>_rbobject__set_<%= a.name %>(VALUE self, VALUE <%= a.rv_name %>) {
  rb_check_frozen(self);
  <%= struct_name %> *<%= short_name %> = get_<%= short_name %>_struct(self);
  <%= short_name %>__require_ready(<%= short_name %>);
  <%= a.cbase %> value = <%= a.param_item_to_c %>;
  if <%= a.validate_fail_condition_c('value') %> rb_raise(rb_eArgError, "Bad value for <%= a.name %>");
  rb_check_frozen(self);
  <%= short_name %>__require_ready(<%= short_name %>);
  <%= short_name %>-><%= a.name %> = value;
  return <%= a.rv_name %>;
}
<% end -%>
<% end -%>
<% narray_attributes.select(&:ruby_read).each do |a| -%>
VALUE <%= short_name %>_rbobject__get_<%= a.name %>(VALUE self) {
  <%= struct_name %> *item = get_<%= short_name %>_struct(self);
  <%= a.narray_fn_name %>(item);
  return item-><%= a.name %>;
}
<% end -%>
<% alloc_attributes.select(&:ruby_read).each do |a| -%>
VALUE <%= short_name %>_rbobject__get_<%= a.name %>(VALUE self) {
  <%= struct_name %> *item = get_<%= short_name %>_struct(self);
  <%= short_name %>__require_ready(item);
  size_t count = item->crow_extent_<%= a.name %>;
  VALUE result = rb_ary_new_capa((long)count);
  for (size_t i = 0; i < count; ++i) rb_ary_push(result, <%= a.array_item_to_ruby_converter %>(item-><%= a.name %>[i]));
  RB_GC_GUARD(self);
  return result;
}
<% end -%>
void init_<%= short_name %>_class(void) {
  rb_define_alloc_func(<%= full_class_name %>, <%= short_name %>_alloc);
  rb_define_method(<%= full_class_name %>, "initialize", <%= short_name %>_rbobject__initialize, <%= init_params.length %>);
  rb_define_method(<%= full_class_name %>, "initialize_copy", <%= short_name %>_rbobject__initialize_copy, 1);
  rb_define_method(<%= full_class_name %>, "to_h", <%= short_name %>_rbobject__to_h, 0);
  rb_define_singleton_method(<%= full_class_name %>, "from_h", <%= short_name %>_rbclass__from_h, -1);
<% attributes.each do |a| -%>
<% if a.ruby_read -%>
  rb_define_method(<%= full_class_name %>, "<%= a.ruby_name %>", <%= short_name %>_rbobject__get_<%= a.name %>, 0);
<% end -%>
<% if a.ruby_write -%>
  rb_define_method(<%= full_class_name %>, "<%= a.ruby_name %>=", <%= short_name %>_rbobject__set_<%= a.name %>, 1);
<% end -%>
<% end -%>
}
