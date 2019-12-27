/*\
 *  Vector - A dynamic array 
 * 
 *  This header file is intended for generation of vector
 *  declarations/definitions for multiple types. The user should simply include
 *  this file like any other header and by adding the following lines:
 *      #define T type
 *      #include "vector.t"
 *  a declaration/definition for the provided `type` is generated.
 *  A struct representing the vector is available as `vector__{type}` and
 *  the associated functions as `vector_{function}__{type}`.
 *  The source file with implementation of vector is `vector.c` which only
 *  includes this header with a `TPL_SOURCE` macro defined, which forces
 *  the included `vector.t` file to generate the definitions.
 * 
 *  For detailed information on the vector interface see the `vector.t` file.
\*/

#ifndef VECTOR_H
#define VECTOR_H

#ifndef TPL_SOURCE
#define TPL_HEADER
#endif

// Insert the desired types here:

#define T int
#include "vector.t"
#define T float
#include "vector.t"

#undef T
#undef TPL_HEADER

#endif