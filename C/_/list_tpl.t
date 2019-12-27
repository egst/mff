#include "tpltools.h"

#ifndef T
    #define T int
#endif

#ifdef TPL_HEADER
    #include <stddef.h>
#else
    #include <stdlib.h>
    #include <string.h>

    #define TPL_HEADER
    #include "list_tpl.t"
    #undef TPL_HEADER
#endif

#ifdef TPL_HEADER
    typedef struct {
        TPL(node, T)* first;
        TPL(node, T)* last;
        TPL(node, T)* cursor;
    } TPL(list, T);

    typedef struct {
        T content;
        TPL(node, T)* prev;
        TPL(node, T)* next;
    } TPL(node, T);
#endif

TPL(list, T) TPL(list_init, T) () TPL_DEF({
    return (TPL(list, T)) {
        .first  = NULL,
        .last   = NULL,
        .cursor = NULL
    };
})

TPL(node, T)* TPL(node_alloc, T) () TPL_DEF({
    TPL(node, T) node = *(TPL(node, T)*) malloc(sizeof(TPL(node, T)));
    node.next = node.prev = NULL;
    return &node;
})

TPL(node, T)* TPL(list_push_back, T) (TPL(list, T)* l, T val) TPL_DEF({
    if (l->last) {
        l->last->next = TPL(node_alloc, T);
        l->last->next->prev = l->last;
        l->last = l->last->next;
    } else {
        l->first = l->last = TPL(node_alloc, T);
    }
    memcpy(&l->last->content, &val, sizeof(T));
    return l->last;
})

TPL(node, T)* TPL(list_push_front, T) (TPL(list, T)* l, T val) TPL_DEF({
    if (l->first) {
        l->first->prev = TPL(node_alloc, T);
        l->first->prev->next = l->first;
        l->first = l->first->prev;
    } else {
        l->first = l->last = TPL(node_alloc, T);
    }
    memcpy(&l->first->content, &val, sizeof(T));
    return l->first;
})

TPL(node, T) TPL(list_pop_back, T) (TPL(list, T)* l) TPL_DEF({
    if (l->last) {
        TPL(node, T)
        l->last->next = TPL(node_alloc, T);
        l->last->next->prev = l->last;
        l->last = l->last->next;
    } else {
        l->first = l->last = TPL(node_alloc, T);
    }
    memcpy(&l->last->content, &val, sizeof(T));
    return l->last;
})

TPL(node, T)* TPL(list_push_front, T) (TPL(list, T)* l, T val) TPL_DEF({
    if (l->first) {
        l->first->prev = TPL(node_alloc, T);
        l->first->prev->next = l->first;
        l->first = l->first->prev;
    } else {
        l->first = l->last = TPL(node_alloc, T);
    }
    memcpy(&l->first->content, &val, sizeof(T));
    return l->first;
})
