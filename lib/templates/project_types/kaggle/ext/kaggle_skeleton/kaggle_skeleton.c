// ext/kaggle_skeleton/kaggle_skeleton.c

#include "base/ruby_module_kaggle_skeleton.h"

/*
 *  Naming conventions used in this C code:
 *
 *  File names
 *    ruby_module_<foo>       :  Ruby bindings for module
 *    ruby_class_<bar>        :  Ruby bindings for class Bar
 *    struct_<baz>            :  C structs for Baz, with memory-management and OO-style "methods"
 *
 *  Variable names
 *    Module_Class_TheThing   :  VALUE container for Ruby Class or Module
 *    The_Thing               :  struct type
 *    the_thing               :  pointer to a struct type
 *
 *  Method names
 *    worker__<desc>          :  OO-style code that takes a Worker C struct as first param
 *    worker_rbobject__<desc> :  Ruby-bound method for KaggleSkeleton::Worker object
 *    worker_rbclass__<desc>  :  Ruby-bound method for KaggleSkeleton::Worker class
 *
*/

void Init_kaggle_skeleton() {
  init_base_module_kaggle_skeleton();
  init_srand_by_time();
  init_classes_kaggle_skeleton();
}
