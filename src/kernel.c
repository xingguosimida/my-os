#include "kernel.h"
#include <stddef.h>
#include <stdint.h>
#include "idt/idt.h"
#include "io/io.h"
#include "memory/heap/kernel_heap.h"

uint16_t *video_mem = 0;
uint16_t terminal_row = 0;
uint16_t terminal_col = 0;

uint16_t terminal_make_char(char c, char colour) {
    return (colour << 8) | c;
}

void terminal_putchar(int x, int y, char c, char colour) {
    video_mem[(y * VGA_WIDTH) + x] = terminal_make_char(c, colour);
}

void terminal_write_char(char c, char colour) {
    if (c == '\n') {
        terminal_row += 1;
        terminal_col = 0;
        return;
    }

    terminal_putchar(terminal_col, terminal_row, c, colour);
    terminal_col += 1;
    if (terminal_col >= VGA_WIDTH) {
        terminal_col = 0;
        terminal_row += 1;
    }
}

void terminal_initialize() {
    video_mem = (uint16_t * )(0xB8000); //   显存的开始地址
    terminal_row = 0;
    terminal_col = 0;
    for (int y = 0; y < VGA_HEIGHT; y++) {
        for (int x = 0; x < VGA_WIDTH; x++) {
            terminal_putchar(x, y, ' ', 0);
        }
    }
}

size_t strlen(const char *str) {
    size_t len = 0;
    while (str[len]) {
        len++;
    }

    return len;
}

void print(const char *str) {
    size_t len = strlen(str);
    for (int i = 0; i < len; i++) {
        terminal_write_char(str[i], 15);
    }
}

void kernel_main() {
    terminal_initialize();
    kernel_heap_init();
    idt_init();
    enable_interrupts();
    void *ptr1 = kernel_malloc(50);
    void *ptr2 = kernel_malloc(5000);
    kernel_free(ptr1);
    void *ptr3 = kernel_malloc(50);
    if (ptr1 || ptr2 || ptr3) {
    }

    print("Hello world!\n");
    // outb(0x60, 0xff);
}