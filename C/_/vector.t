/*\
 *  # Generic vector declarations/definitions
 * 
 *  This header/source file must be included by the `vector.h` header file only.
 *  It contains no inclusion guard as it is intended for
 *  "parametrized inclusion". Repeated inclusion must be avoided manually in
 *  the `vector.h` header file. It serves as both a header and a source file.
 *  When a `TPL_HEADER` macro is defined before `#include` of this file, it acts
 *  as a header file, and as a source file otherwise. Before `#include`,
 *  a `T` macro must be defined to the desired type. This header/source file is
 *  then included for each such type. The default `T` type is `int`.
 * 
 *  The vector is represented as a struct containing its size, capacity and
 *  a pointer to its first element.
 * 
 *  ## Interface:
 * 
 *  TPL(vector, T) TPL(vector_init, T) (void)
 *      Initializes an empty vecotor.
 *      Returns the vector.
 *  TPL(vector, T) TPL(vector_init_from, T) (T** from, size_t length)
 *      Initializes a vector of length `length`
 *      and coppies `length` contents from `from`.
 *      `from` must be a contiguous storage of length at least `length`.
 *      Returns the vector.
 *  T* TPL(vector_begin, T) (const TPL(vector, T)* vector)
 *      Returns a pointer to first `vector`'s element.
 *  T* TPL(vector_end, T) (const TPL(vector, T)* vector)
 *      Returns a pointer pointing past the last `vector`'s element.
 *  T* TPL(vector_push, T) (TPL(vector, T)* vector, T val)
 *      Pushes `val` to the end of the `vector`
 *      in ammortized time complexity of O(1).
 *      May reallocate the whole vector.
 *      Returns pointer to the pushed element.
 *  T TPL(vector_pop, T) (TPL(vector, T)* vector)
 *      Pops the last `vector`'s element.
 *      May reallocate the whole vector,
 *      but will probably just free a part of the previously allocated memory.
 *      Returns a copy of the popped element.
 *  void TPL(vector_just_pop, T) (TPL(vector, T)* vector)
 *      Same as `TPL(vector_pop, T)`,
 *      but doesn't copy the popped element.
\*/

#ifdef TPL_HEADER
    #include <stddef.h>
    #include <stdbool.h>
#else
    #include <string.h>
    #include <stdlib.h>

    #define TPL_HEADER
    #include "vector_tpl.t"
#endif

#include "tpltools.h"

#ifndef T
    #define T int
#endif

#ifdef TPL_HEADER
    typedef struct {
        size_t size;
        size_t capacity;
        T*     data;
    } TPL(vector, T);
#endif

TPL(vector, T) TPL(vector_init, T) () TPL_DEF({
    const size_t capacity = 4;
    return (TPL(vector, T)) ({
        .size     = 0,
        .capacity = capacity,
        .data     = (T*) malloc(capacity * sizeof(T))
    });
})

TPL(vector, T) TPL(vector_init_from, T) (T* from, size_t size) TPL_DEF({
    TPL(vector, T) v = ({
        .size     = size,
        .capacity = size,
        .data     = (T*) malloc(size * sizeof(T))
    });
    memcpy(v.data, from, size * sizeof(T));
    return v;
})

T* TPL(vector_begin, T) (const TPL(vector, T)* v) TPL_DEF({
    return v->data;
})

T* TPL(vector_end, T) (const TPL(vector, T)* v) TPL_DEF({
    return v->data + v->size;
})

T* TPL(vector_last, T) (const TPL(vector, T)* v) TPL_DEF({
    return TPL(vector_empty, T)(v) ? NULL : TPL(vector_end, T)(v) - 1;
})

bool TPL(vector_empty, T) (const TPL(vector, T)* v) TPL_DEF({
    return TPL(vector_begin, T)(v) == TPL(vector_end, T)(v);
})

T* TPL(vector_push, T) (TPL(vector, T)* v, T val) TPL_DEF({
    v->size += 1;
    if (v->size >= v->capacity)
        v->data = (T*) realloc(v->data, (v->capacity *= 2) * sizeof(T));
    T* last = TPL(vector_end, T)(v) - 1;
    memcpy(last, &val, sizeof(T));
    return last;
})

T TPL(vector_pop, T) (TPL(vector, T)* v) TPL_DEF({
    T popped;
    memcpy(&popped, TPL(vector_end, T) - 1, sizeof(T));
    v->size -= 1;
    if (v->size * 2 <= v->capacity)
        v->data = (T*) realloc(v->data, (v->capacity /= 2) * sizeof(T));
    return popped;
})

void TPL(vector_just_pop, T) (TPL(vector, T)* v) TPL_DEF({
    v->size -= 1;
    if (v->size * 2 <= v->capacity)
        v->data = (T*) realloc(v->data, (v->capacity /= 2) * sizeof(T));
})

#undef T