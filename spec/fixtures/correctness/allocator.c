#include "allocator.h"
long test_remaining = -1, test_outstanding = 0;
static void check_failure(void) {
  if (test_remaining == 0) rb_raise(rb_eNoMemError, "controlled allocation failure");
  if (test_remaining > 0) --test_remaining;
}
void *test_malloc(size_t size) {
  check_failure();
  void *ptr = ruby_xmalloc(size);
  ++test_outstanding;
  return ptr;
}
void *test_calloc(size_t count, size_t size) {
  check_failure();
  void *ptr = ruby_xcalloc(count, size);
  ++test_outstanding;
  return ptr;
}
void test_free(void *ptr) {
  if (ptr) { --test_outstanding; ruby_xfree(ptr); }
}
