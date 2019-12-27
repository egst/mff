#include "min.h"

int min (int from[], size_t count) {
    if (count < 1) return -2;
    int min = from[0];
    for (size_t i = 1; i < count; ++i)
        if (from[i] < min)
            min = from[i];
    return min;
}