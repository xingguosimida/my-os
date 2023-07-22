#ifndef KERNEL_HEAP_H
#define KERNEL_HEAP_H

#include <stddef.h>

void *kernel_malloc(size_t size);

void kernel_heap_init();

void kernel_free(void *ptr);

#endif