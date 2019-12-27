#ifndef TPLTOOLS_H
#define TPLTOOLS_H

#define TPL_CAT(name, type)     name ## __ ## type
#define TPL(name, type)         TPL_CAT(name, type)

#ifdef TPL_HEADER
    #define TPL_DEF(definition) ;
#else
    #define TPL_DEF(definition) definition
#endif

#endif