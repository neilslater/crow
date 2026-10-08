// ext/<%= lib_short_name %>/base/struct_<%= short_name %>.c
#include "base/struct_<%= short_name %>.h"

typedef struct {
  <%= struct_name %> *crow_destination;
  <%= struct_name %> *crow_source;
  VALUE crow_owner, crow_receiver, crow_hash;
  const VALUE *crow_args;
  int crow_operation; /* native init, Ruby init, copy, restore */
<% init_params.each do |p| -%>
  <%= p.declare %>
<% end -%>
} <%= short_name %>__transaction;

void <%= short_name %>__require_ready(<%= struct_name %> *item) {
  if (!item || item->crow_state != 2) rb_raise(rb_eRuntimeError, "<%= short_name %> is not initialized");
}

static void <%= short_name %>__clear(<%= struct_name %> *item) {
<% alloc_attributes.each do |a| -%>
  xfree(item-><%= a.name %>);
<% end -%>
  memset(item, 0, sizeof(*item));
<% attributes.select(&:needs_gc_mark?).each do |a| -%>
  item-><%= a.name %> = Qnil;
<% end -%>
}

<%= struct_name %> *<%= short_name %>__create(void) {
  <%= struct_name %> *item = ruby_xcalloc(1, sizeof(*item));
<% attributes.select(&:needs_gc_mark?).each do |a| -%>
  item-><%= a.name %> = Qnil;
<% end -%>
  return item;
}

void <%= short_name %>__destroy(<%= struct_name %> *item) {
  if (!item) return;
  <%= short_name %>__clear(item);
  xfree(item);
}

void <%= short_name %>__gc_mark(<%= struct_name %> *item) {
  if (!item) return;
<% attributes.select(&:needs_gc_mark?).each do |a| -%>
  rb_gc_mark(item-><%= a.name %>);
<% end -%>
}

static VALUE <%= short_name %>__divide(VALUE left, VALUE right) {
  if (RTEST(rb_equal(right, INT2FIX(0)))) rb_raise(rb_eRangeError, "Division by zero in storage expression");
  VALUE result = rb_funcall(left, rb_intern("/"), 1, right);
  int left_negative = RTEST(rb_funcall(left, rb_intern("<"), 1, INT2FIX(0)));
  int right_negative = RTEST(rb_funcall(right, rb_intern("<"), 1, INT2FIX(0)));
  if (left_negative != right_negative && !RTEST(rb_equal(rb_funcall(left, rb_intern("%"), 1, right), INT2FIX(0))))
    result = rb_funcall(result, rb_intern("+"), 1, INT2FIX(1));
  RB_GC_GUARD(left);
  RB_GC_GUARD(right);
  return result;
}

static size_t <%= short_name %>__dimension(VALUE value) {
  if (RTEST(rb_funcall(value, rb_intern("<"), 1, INT2FIX(0))))
    rb_raise(rb_eArgError, "Negative storage dimension");
  if (RTEST(rb_funcall(value, rb_intern(">"), 1, SIZET2NUM(SIZE_MAX))))
    rb_raise(rb_eRangeError, "Storage dimension overflow");
  return NUM2SIZET(value);
}

static size_t <%= short_name %>__bytes(size_t count, size_t width) {
  if (count > SIZE_MAX / width || count > LONG_MAX)
    rb_raise(rb_eRangeError, "Storage byte count overflow");
  return count * width;
}

<% narray_attributes.each do |a| -%>
static narray_t *<%= short_name %>__validate_<%= a.name %>(<%= struct_name %> *item) {
  narray_t *array;
  if (rb_obj_class(item-><%= a.name %>) != <%= a.narray_enum_type %>)
    rb_raise(rb_eTypeError, "<%= a.name %>: incorrect NArray dtype");
  GetNArray(item-><%= a.name %>, array);
  if (NA_TYPE(array) != NARRAY_DATA_T || NA_NDIM(array) != <%= a.init.normalized_shapes.length %>)
    rb_raise(rb_eArgError, "<%= a.name %>: incorrect NArray layout or rank");
  for (size_t i = 0; i < <%= a.init.normalized_shapes.length %>; ++i)
    if (NA_SHAPE(array)[i] != item->crow_shape_<%= a.name %>[i])
      rb_raise(rb_eArgError, "<%= a.name %>: changed NArray shape");
  if (!RTEST(na_check_contiguous(item-><%= a.name %>)) || TEST_COLUMN_MAJOR(item-><%= a.name %>))
    rb_raise(rb_eArgError, "<%= a.name %>: expected row-major storage");
  return array;
}

narray_t *<%= a.narray_fn_name %>(<%= struct_name %> *item) {
  <%= short_name %>__require_ready(item);
  return <%= short_name %>__validate_<%= a.name %>(item);
}
size_t *<%= a.shape_fn_name %>(<%= struct_name %> *item) { return NA_SHAPE(<%= a.narray_fn_name %>(item)); }
size_t <%= a.size_fn_name %>(<%= struct_name %> *item) { return NA_SIZE(<%= a.narray_fn_name %>(item)); }
int <%= a.rank_fn_name %>(<%= struct_name %> *item) { return NA_NDIM(<%= a.narray_fn_name %>(item)); }
<%= a.item_ctype %> *<%= a.ptr_fn_name %>(<%= struct_name %> *item) {
  <%= a.narray_fn_name %>(item);
  return (<%= a.item_ctype %> *)na_get_pointer_for_read_write(item-><%= a.name %>);
}

static void <%= short_name %>__import_<%= a.name %>(<%= struct_name %> *item, VALUE source) {
  narray_t *array;
  if (rb_obj_class(source) != <%= a.narray_enum_type %>) rb_raise(rb_eTypeError, "<%= a.name %>: incorrect NArray dtype");
  GetNArray(source, array);
  if (NA_NDIM(array) != <%= a.init.normalized_shapes.length %>) rb_raise(rb_eArgError, "<%= a.name %>: incorrect rank");
  for (size_t i = 0; i < <%= a.init.normalized_shapes.length %>; ++i)
    if (NA_SHAPE(array)[i] != item->crow_shape_<%= a.name %>[i]) rb_raise(rb_eArgError, "<%= a.name %>: incorrect shape");
  item-><%= a.name %> = nary_new(<%= a.narray_enum_type %>, <%= a.init.normalized_shapes.length %>, item->crow_shape_<%= a.name %>);
  na_store(item-><%= a.name %>, source);
  <%= short_name %>__validate_<%= a.name %>(item);
  RB_GC_GUARD(source);
}
<% end -%>

static void <%= short_name %>__populate(<%= short_name %>__transaction *crow_tx, <%= struct_name %> *<%= short_name %>) {
<% init_params.each_with_index do |p,index| -%>
  <%= p.as_param %> = crow_tx-><%= p.name %>;
  if (crow_tx->crow_operation == 1) <%= p.name %> = <%= p.class.ruby_to_c("crow_tx->crow_args[#{index}]") %>;
<% end -%>
<% if restoration_error.nil? -%>
  if (crow_tx->crow_operation == 3) {
<% stored_attributes.reject(&:narray?).each do |a| -%>
    VALUE crow_value_<%= a.name %> = rb_hash_lookup2(crow_tx->crow_hash, ID2SYM(rb_intern("<%= a.name %>")), Qundef);
    if (crow_value_<%= a.name %> == Qundef) rb_raise(rb_eArgError, "Missing key :<%= a.name %>");
    <%= short_name %>-><%= a.name %> = <%= a.class.ruby_to_c("crow_value_#{a.name}") %>;
<% end -%>
<% restored_params.each do |param,a| -%>
    <%= param %> = <%= short_name %>-><%= a.name %>;
<% end -%>
  }
<% end -%>
<% init_params.select(&:validate?).each do |p| -%>
  if ((crow_tx->crow_operation != 3<% if restored_params.key?(p.name) %> || 1<% end %>) && <%= p.validate_fail_condition_c(p.name) %>) rb_raise(rb_eArgError, "Bad value for <%= p.name %>");
<% end -%>
  if (crow_tx->crow_operation != 3) {
<% simple_attributes.each do |a| -%>
    <%= short_name %>-><%= a.name %> = <%= a.default %>;
<% end -%>
<% simple_attributes_with_init.each do |a| -%>
    <%= short_name %>-><%= a.name %> = <%= a.init_expr_c(init_context: true) %>;
<% end -%>
  }
<% if restoration_error.nil? -%>
  else {
<% restore_order.each do |a| -%>
    <%= short_name %>-><%= a.name %> = <%= restore_scalar_c(a) %>;
<% end -%>
  }
<% end -%>
<% simple_attributes.select(&:validate?).each do |a| -%>
  if <%= a.validate_fail_condition_c %> rb_raise(rb_eArgError, "Bad value for <%= a.name %>");
<% end -%>
<% alloc_attributes.each do |a| -%>
  <%= short_name %>->crow_extent_<%= a.name %> = <%= dimension_c(pointer_dimension(a)) %>;
  size_t crow_bytes_<%= a.name %> = <%= short_name %>__bytes(<%= short_name %>->crow_extent_<%= a.name %>, sizeof(<%= a.cbase %>));
  if (crow_bytes_<%= a.name %>) <%= short_name %>-><%= a.name %> = ruby_xmalloc(crow_bytes_<%= a.name %>);
  for (size_t i = 0; i < <%= short_name %>->crow_extent_<%= a.name %>; ++i)
    <%= short_name %>-><%= a.name %>[i] = <%= a.init_expr_c %>;
<% end -%>
<% narray_attributes.each do |a| -%>
  size_t crow_count_<%= a.name %> = 1;
<% a.init.normalized_shapes.each_with_index do |expr,index| -%>
  <%= short_name %>->crow_shape_<%= a.name %>[<%= index %>] = <%= dimension_c(expr) %>;
  if (<%= short_name %>->crow_shape_<%= a.name %>[<%= index %>] && crow_count_<%= a.name %> > SIZE_MAX / <%= short_name %>->crow_shape_<%= a.name %>[<%= index %>])
    rb_raise(rb_eRangeError, "NArray size overflow");
  crow_count_<%= a.name %> *= <%= short_name %>->crow_shape_<%= a.name %>[<%= index %>];
<% end -%>
  <%= short_name %>__bytes(crow_count_<%= a.name %>, sizeof(<%= a.item_ctype %>));
<% if a.store -%>
  if (crow_tx->crow_operation == 3) {
    VALUE value = rb_hash_lookup2(crow_tx->crow_hash, ID2SYM(rb_intern("<%= a.name %>")), Qundef);
    if (value == Qundef) rb_raise(rb_eArgError, "Missing key :<%= a.name %>");
    <%= short_name %>__import_<%= a.name %>(<%= short_name %>, value);
  } else
<% end -%>
  {
    <%= short_name %>-><%= a.name %> = nary_new(<%= a.narray_enum_type %>, <%= a.init.normalized_shapes.length %>, <%= short_name %>->crow_shape_<%= a.name %>);
    <%= a.item_ctype %> *data = (<%= a.item_ctype %> *)na_get_pointer_for_write(<%= short_name %>-><%= a.name %>);
    for (size_t i = 0; i < crow_count_<%= a.name %>; ++i) data[i] = <%= a.init_expr_c %>;
  }
<% end -%>
}

static void <%= short_name %>__copy_fields(<%= struct_name %> *copy, <%= struct_name %> *orig) {
  <%= short_name %>__require_ready(orig);
<% simple_attributes.each do |a| -%>
  copy-><%= a.name %> = orig-><%= a.name %>;
<% end -%>
<% alloc_attributes.each do |a| -%>
  copy->crow_extent_<%= a.name %> = orig->crow_extent_<%= a.name %>;
  size_t bytes_<%= a.name %> = <%= short_name %>__bytes(copy->crow_extent_<%= a.name %>, sizeof(<%= a.cbase %>));
  if (bytes_<%= a.name %>) {
    copy-><%= a.name %> = ruby_xmalloc(bytes_<%= a.name %>);
    memcpy(copy-><%= a.name %>, orig-><%= a.name %>, bytes_<%= a.name %>);
  }
<% end -%>
<% narray_attributes.each do |a| -%>
  <%= a.narray_fn_name %>(orig);
  memcpy(copy->crow_shape_<%= a.name %>, orig->crow_shape_<%= a.name %>, sizeof(copy->crow_shape_<%= a.name %>));
  <%= short_name %>__import_<%= a.name %>(copy, orig-><%= a.name %>);
<% end -%>
}

static VALUE <%= short_name %>__work(VALUE opaque) {
  <%= short_name %>__transaction *tx = (<%= short_name %>__transaction *)opaque;
  tx->crow_owner = Data_Wrap_Struct(rb_cObject, <%= short_name %>__gc_mark, <%= short_name %>__destroy, NULL);
  DATA_PTR(tx->crow_owner) = <%= short_name %>__create();
  <%= struct_name %> *temporary = DATA_PTR(tx->crow_owner);
  if (tx->crow_operation == 2) <%= short_name %>__copy_fields(temporary, tx->crow_source);
  else <%= short_name %>__populate(tx, temporary);
  if (!NIL_P(tx->crow_receiver)) rb_check_frozen(tx->crow_receiver);
  if (tx->crow_destination->crow_state != 1) rb_raise(rb_eRuntimeError, "Changed initialization state");
  *tx->crow_destination = *temporary;
  tx->crow_destination->crow_state = 2;
  memset(temporary, 0, sizeof(*temporary));
<% attributes.select(&:needs_gc_mark?).each do |a| -%>
  temporary-><%= a.name %> = Qnil;
<% end -%>
  return Qnil;
}

static VALUE <%= short_name %>__cleanup(VALUE opaque) {
  <%= short_name %>__transaction *tx = (<%= short_name %>__transaction *)opaque;
  if (!NIL_P(tx->crow_owner)) {
    <%= short_name %>__destroy(DATA_PTR(tx->crow_owner));
    DATA_PTR(tx->crow_owner) = NULL;
  }
  if (tx->crow_destination->crow_state == 1) tx->crow_destination->crow_state = 0;
  return Qnil;
}

static void <%= short_name %>__run(<%= short_name %>__transaction *tx) {
  if (!NIL_P(tx->crow_receiver)) rb_check_frozen(tx->crow_receiver);
  if (!tx->crow_destination || tx->crow_destination->crow_state != 0) rb_raise(rb_eRuntimeError, "Already initialized or initializing");
  tx->crow_owner = Qnil;
  tx->crow_destination->crow_state = 1;
  rb_ensure(<%= short_name %>__work, (VALUE)tx, <%= short_name %>__cleanup, (VALUE)tx);
  RB_GC_GUARD(tx->crow_owner);
  RB_GC_GUARD(tx->crow_receiver);
  RB_GC_GUARD(tx->crow_hash);
}

void <%= short_name %>__init(<%= struct_name %> *<%= short_name %><% init_params.each do |p| %>, <%= p.as_param %><% end %>) {
  <%= short_name %>__transaction crow_tx = {0};
  crow_tx.crow_destination = <%= short_name %>; crow_tx.crow_receiver = Qnil; crow_tx.crow_hash = Qnil;
<% init_params.each do |p| -%>
  crow_tx.<%= p.name %> = <%= p.name %>;
<% end -%>
  <%= short_name %>__run(&crow_tx);
}
void <%= short_name %>__initialize_ruby(<%= struct_name %> *item, VALUE receiver, const VALUE *args) {
  <%= short_name %>__transaction tx = {0};
  tx.crow_destination = item; tx.crow_receiver = receiver; tx.crow_hash = Qnil; tx.crow_args = args; tx.crow_operation = 1;
  <%= short_name %>__run(&tx);
}
void <%= short_name %>__restore(<%= struct_name %> *item, VALUE receiver, VALUE hash) {
<% if restoration_error -%>
  rb_raise(rb_eArgError, "Restoration unsupported: %s", <%= restoration_error.inspect %>);
<% else -%>
  <%= short_name %>__transaction tx = {0};
  tx.crow_destination = item; tx.crow_receiver = receiver; tx.crow_hash = hash; tx.crow_operation = 3;
  <%= short_name %>__run(&tx);
<% end -%>
}
void <%= short_name %>__copy_ruby(<%= struct_name %> *copy, <%= struct_name %> *orig, VALUE receiver) {
  <%= short_name %>__transaction tx = {0};
  tx.crow_destination = copy; tx.crow_source = orig; tx.crow_receiver = receiver; tx.crow_hash = Qnil; tx.crow_operation = 2;
  <%= short_name %>__run(&tx);
}
void <%= short_name %>__deep_copy(<%= struct_name %> *copy, <%= struct_name %> *orig) {
  if (copy == orig) return;
  <%= short_name %>__copy_ruby(copy, orig, Qnil);
}
static VALUE <%= short_name %>__clone_work(VALUE opaque) {
  <%= short_name %>__transaction *tx = (<%= short_name %>__transaction *)opaque;
  <%= short_name %>__deep_copy(tx->crow_destination, tx->crow_source);
  return Qnil;
}
<%= struct_name %> *<%= short_name %>__clone(<%= struct_name %> *orig) {
  int state;
  <%= short_name %>__transaction tx = {0};
  tx.crow_source = orig; tx.crow_destination = <%= short_name %>__create();
  rb_protect(<%= short_name %>__clone_work, (VALUE)&tx, &state);
  if (state) { <%= short_name %>__destroy(tx.crow_destination); rb_jump_tag(state); }
  return tx.crow_destination;
}
