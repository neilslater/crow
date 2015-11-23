// ext/kaggle_skeleton/rub_module_kaggle_skeleton.c

#include "ruby_module_kaggle_skeleton.h"

/* @overload srand( seed )
 * Seed the random number generator used inside KaggleSkeleton.
 * @param [Integer] seed 32-bit seed number
 * @return [nil]
 */
static VALUE rbmodule__srand( VALUE self, VALUE rv_seed ) {
  init_genrand( NUM2ULONG( rv_seed ) );
  return Qnil;
}

static unsigned long kaggle_skeleton_srand_seed[640];

/* @overload srand_array( seed )
 * Seed the random number generator used inside KaggleSkeleton.
 * @param [Array<Integer>] seed an array of up to 640 times 32 bit seed numbers
 * @return [nil]
 */
static VALUE rbmodule__srand_array( VALUE self, VALUE rv_seed_array ) {
  int i, n;
  Check_Type( rv_seed_array, T_ARRAY );
  n = FIX2INT( rb_funcall( rv_seed_array, rb_intern("count"), 0 ) );
  if ( n < 1 ) {
    rb_raise( rb_eArgError, "empty array cannot be used to seed RNG" );
  }
  if ( n > 640 ) { n = 640; }
  for ( i = 0; i < n; i++ ) {
    kaggle_skeleton_srand_seed[i] = NUM2ULONG( rb_ary_entry( rv_seed_array, i ) );
  }
  init_by_array( kaggle_skeleton_srand_seed, n );
  return Qnil;
}

/* @overload rand( )
 * @!visibility private
 * Use the random number generator (Ruby binding only used for tests)
 * @return [Float] random number in range 0.0..1.0
 */
static VALUE rbmodule__rand_float( VALUE self ) {
  return FLT2NUM( genrand_real1() );
}

////////////////////////////////////////////////////////////////////////////////////////////////////

VALUE KaggleSkeleton = Qnil;
<% structs.each do |s| -%>
VALUE <%= s.full_class_name %> = Qnil;
<% end -%>

void init_module_kaggle_skeleton() {
  KaggleSkeleton = rb_define_module( "KaggleSkeleton" );
<% structs.each do |s| -%>
  <%= s.full_class_name %> = rb_define_class_under( KaggleSkeleton, "<%= s.rb_class_name %>", rb_cObject );
<% end -%>

  rb_define_singleton_method( KaggleSkeleton, "srand", rbmodule__srand, 1 );
  rb_define_singleton_method( KaggleSkeleton, "srand_array", rbmodule__srand_array, 1 );
  rb_define_singleton_method( KaggleSkeleton, "rand", rbmodule__rand_float, 0 );

<% structs.each do |s| -%>
  init_<%= s.short_name %>_class();
<% end -%>
  init_srand_by_time();
}
