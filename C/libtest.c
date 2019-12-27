#include "min.h"
#include <stdio.h>

int main () {
    int ns[] = {1, 2, 3};

    printf("%i", min(ns, 0));

    return 0;
}

/*

cd libs
gcc -o bin/libmin.o -I inc -c src/min.c
gcc -o bin/libmin.so -shared bin/libmin.o
cd ..
gcc -o bin/dyn -I libs/inc -L libs/bin -Wl,-rpath libs/bin libtest.c -l min

*/
