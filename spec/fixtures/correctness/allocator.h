#ifndef CROW_TEST_ALLOCATOR_H
#define CROW_TEST_ALLOCATOR_H
#include <ruby.h>
extern long test_remaining, test_outstanding;
void *test_malloc(size_t size);
void *test_calloc(size_t count, size_t size);
void test_free(void *ptr);
#endif
