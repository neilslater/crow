#include "ruby/class_buffers.h"
#include "base/ruby_class_scalar.h"
#include "base/ruby_class_array.h"
#include "allocator.h"
static VALUE allocations(VALUE klass) { return LONG2NUM(test_outstanding); }
static VALUE fail_after(VALUE klass, VALUE number) { test_remaining = NUM2LONG(number); return number; }
static VALUE native_clone(VALUE self) {
  Buffers *source = get_buffers_struct(self);
  Buffers *copy = buffers__clone(source);
  VALUE result = buffers_as_ruby_class(copy, rb_obj_class(self));
  RB_GC_GUARD(self);
  return result;
}
static VALUE first_value(VALUE self) {
  Array *item = get_array_struct(self);
  double *ptr = array__get_data_ptr(item);
  return DBL2NUM(ptr[0]);
}
static VALUE change_count(VALUE self, VALUE count) {
  get_buffers_struct(self)->count = NUM2INT(count);
  return count;
}
static VALUE extract_scalar(VALUE klass, VALUE object) {
  get_scalar_struct(object);
  return Qtrue;
}
static VALUE legacy_scalar(VALUE klass) {
  Scalar *item = scalar__create();
  scalar__init(item);
  return scalar_as_ruby_class(item, klass);
}
static const rb_data_type_t foreign_type = {"test", {0, RUBY_DEFAULT_FREE, 0}, 0, 0, 0};
static VALUE typed_scalar(VALUE klass) {
  return TypedData_Wrap_Struct(klass, &foreign_type, NULL);
}
static VALUE null_scalar(VALUE klass) {
  return Data_Wrap_Struct(klass, scalar__gc_mark, scalar__destroy, NULL);
}
void init_class_buffers_ext(void) {
  rb_define_singleton_method(Contract_Buffers, "allocations", allocations, 0);
  rb_define_singleton_method(Contract_Buffers, "fail_after", fail_after, 1);
  rb_define_method(Contract_Buffers, "native_clone", native_clone, 0);
  rb_define_method(Contract_Buffers, "change_count", change_count, 1);
  rb_define_method(Contract_Array, "native_first", first_value, 0);
  rb_define_singleton_method(Contract_Scalar, "extract", extract_scalar, 1);
  rb_define_singleton_method(Contract_Scalar, "legacy", legacy_scalar, 0);
  rb_define_singleton_method(Contract_Scalar, "typed", typed_scalar, 0);
  rb_define_singleton_method(Contract_Scalar, "null", null_scalar, 0);
}
