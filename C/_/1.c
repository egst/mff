#include <stdio.h>

#define arrsize(arr, t) sizeof(arr) / sizeof(t)

// Switch between void pointer based polymorphism and macro based polymorphism:
#define MACROVECTOR

#ifdef MACROVECTOR

#include "tpltools.h"
#include "vector.h"

int main () {
    // Con: No polymorphism, type suffixes must be used after explicitly generating definitions for the given type.
    // Pro: Type safety.
    // Pro: Type sizes are calculated internally.
    //vector__int   vi = vector_init__int();
    vector__int   vi = vector_init__int();
    vector__float vf = vector_init__float();

    // Pro: Elements don't have to passed as pointers:
    vector_push__int(&vi, 1);
    vector_push__int(&vi, 2);
    vector_push__int(&vi, 3);
    vector_push__int(&vi, 4);
    vector_push__int(&vi, 5);
    vector_push__int(&vi, 6);

    vector_push__float(&vf, 1);
    vector_push__float(&vf, 2);
    vector_push__float(&vf, 3);
    vector_push__float(&vf, 4);
    vector_push__float(&vf, 5);
    vector_push__float(&vf, 6);

    for (int* it = vector_begin__int(&vi); it != vector_end__int(&vi); ++it)
        printf("%i\n", *it);
    for (float* it = vector_begin__float(&vf); it != vector_end__float(&vf); ++it)
        printf("%f\n", *it);

    return 0;
}

#else

#include "vector_void.h"

int main () {
    // Pro: "Polymorphic" functions.
    // Con: Type sizes muset be provided explicitly.
    // Con: No type safety. Caller must keep track of the types.
    int intvals[] = {1, 2, 3, 4, 5, 6};
    vector vi = vector_init_from(sizeof(int), arrsize(intvals, int), (void**) intvals);
    float floatvals[] = {1, 2, 3, 4, 5, 6};
    vector vf = vector_init_from(sizeof(int), arrsize(floatvals, int), (void**) floatvals);

    // Con: Elements must be passed around as pointers.
    int x = 20;
    vector_push(&vi, &x);

    for (int* it = vector_begin(&vi); it != vector_end(&vi); ++it)
        printf("%i\n", *it);
    for (float* it = vector_begin(&vf); it != vector_end(&vf); ++it)
        printf("%f\n", *it);

    return 0;
}

#endif