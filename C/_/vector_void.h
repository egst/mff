#include <stddef.h>
#include <string.h>
#include <stdlib.h>

typedef unsigned char byte;

typedef struct {
    size_t size;
    size_t length;
    size_t capacity;
    void*  data;
} vector;

vector vector_init (size_t size) {
    size_t capacity = 4;
    return (vector) {
        .size     = size,
        .length   = 0,
        .capacity = capacity,
        .data     = malloc(capacity * size)
    };
}
vector vector_init_from (size_t size, size_t length, void* vals[]) {
    vector v = {
        .size     = size,
        .length   = length,
        .capacity = length,
        .data     = malloc(length * size)
    };
    memcpy(v.data, vals, length * size);
    return v;
}
void* vector_begin (const vector* v) {
    return v->data;
}
void* vector_end (const vector* v) {
    return (byte*) v->data + v->length * v->size;
}
void* vector_push (vector* v, const void* val) {
    if (v->length >= v->capacity)
        v->data = realloc(v->data, (v->capacity *= 2) * v->size);
    void* last = vector_end(v);
    memcpy(last, val, v->size);
    v->length += 1;
    return last;
}