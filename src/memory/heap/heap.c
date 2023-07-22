#include "heap.h"
#include <stdbool.h>
#include "status.h"
#include "memory/memory.h"

static bool heap_validate_alignment(void *ptr) {
    return ((unsigned int) ptr % HEAP_BLOCK_SIZE) == 0;
}

static bool heap_validate_table(void *ptr, void *end, struct heap_table *heap_table) {
    int res = 0;
    size_t table_size = (size_t)(end - ptr);
    size_t total_blocks = table_size / HEAP_BLOCK_SIZE;
    if (heap_table->total != total_blocks) {
        res = -KERNEL_ARGUMENT_ERROR;
        goto out;
    }
    out:
    return res;
}

int heap_create(struct heap *heap, void *ptr, void *end, struct heap_table *heap_table) {
    int res = KERNEL_OK;
    if (!heap_validate_alignment(ptr) || !heap_validate_alignment(end)) {
        res = -KERNEL_ARGUMENT_ERROR;
        goto out;
    }
    set_memory(heap, 0, sizeof(struct heap));
    heap->start_address = ptr;
    heap->heap_table = heap_table;

    res = heap_validate_table(ptr, end, heap_table);
    if (res < 0) {
        goto out;
    }

    size_t table_size = sizeof(HEAP_BLOCK_TABLE_ENTRY) * heap_table->total;

    set_memory(heap_table->entries, HEAP_BLOCK_TABLE_ENTRY_FREE, table_size);

    out:
    return res;
}

static uint32_t heap_align_value_to_upper(size_t size) {
    if ((size % HEAP_BLOCK_SIZE) == 0) {
        return size;
    }
    return (size - (size % HEAP_BLOCK_SIZE) + HEAP_BLOCK_SIZE);
}

static int heap_get_entry_type(HEAP_BLOCK_TABLE_ENTRY entry) {
    return entry & 0x0f;
}

int heap_find_start_block(struct heap *heap, uint32_t total_blocks) {
    struct heap_table *heap_table = heap->heap_table;
    int current_block = 0;
    int start_block = -1;
    for (size_t i = 0; i < heap_table->total; i++) {
        if (heap_get_entry_type(heap_table->entries[i]) != HEAP_BLOCK_TABLE_ENTRY_FREE) {
            current_block = 0;
            start_block = -1;
            continue;
        }
        if (start_block == -1) {
            start_block = i;
        }
        current_block++;

        if (current_block == total_blocks) {
            break;
        }
    }
    if (start_block == -1) {
        return -KERNEL_NO_MEMORY_ERROR;
    }
    return start_block;
}

void heap_mark_blocks_taken(struct heap *heap, int start_block, uint32_t total_blocks) {
    int end_block = (start_block + total_blocks) - 1;
    HEAP_BLOCK_TABLE_ENTRY entry = HEAP_BLOCK_TABLE_ENTRY_TAKEN | HEAP_BLOCK_IS_FIRST;
    if (total_blocks > 1) {
        entry |= HEAP_BLOCK_HAS_NEXT;
    }

    for (int i = start_block; i <= end_block; i++) {
        heap->heap_table->entries[i] = entry;
        entry = HEAP_BLOCK_TABLE_ENTRY_TAKEN;
        if (i != end_block - 1) {
            entry |= HEAP_BLOCK_HAS_NEXT;
        }
    }
}

void *heap_block_to_address(struct heap *heap, int block) {
    return heap->start_address + (block * HEAP_BLOCK_SIZE);
}

void *heap_malloc_blocks(struct heap *heap, uint32_t total_blocks) {
    void *address = 0;
    int start_block = heap_find_start_block(heap, total_blocks);
    if (start_block < 0) {
        goto out;
    }
    address = heap_block_to_address(heap, start_block);
    heap_mark_blocks_taken(heap, start_block, total_blocks);

    out:
    return address;
}

int heap_address_to_block(struct heap *heap, void *address) {
    return ((int) (address - heap->start_address)) / HEAP_BLOCK_SIZE;
}

void heap_mark_blocks_free(struct heap *heap, int starting_block) {
    struct heap_table *table = heap->heap_table;
    for (int i = starting_block; i < (int) table->total; i++) {
        HEAP_BLOCK_TABLE_ENTRY entry = table->entries[i];
        table->entries[i] = HEAP_BLOCK_TABLE_ENTRY_FREE;
        if (!(entry & HEAP_BLOCK_HAS_NEXT)) {
            break;
        }
    }
}

void *heap_malloc(struct heap *heap, size_t size) {
    size_t aligned_size = heap_align_value_to_upper(size);
    uint32_t total_blocks = aligned_size / HEAP_BLOCK_SIZE;
    return heap_malloc_blocks(heap, total_blocks);
}

void heap_free(struct heap *heap, void *ptr) {
    heap_mark_blocks_free(heap, heap_address_to_block(heap, ptr));
}
