#include "memory.h"

/**
 *  char_ptr[i] 是指针算术的一种形式，它相当于 *(char_ptr + i)，即访问指针 char_ptr 偏移 i 个 char 类型的大小后的内存位置，并将值 (char) c 存储到该位置。
 * @param ptr
 * @param c
 * @param size
 */
void *set_memory(void *ptr, int c, size_t size) {
    char *char_ptr = (char *) ptr;
    for (int i = 0; i < size; i++) {
        char_ptr[i] = (char) c;
    }
    return ptr;
}