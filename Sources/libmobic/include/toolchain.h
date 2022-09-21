//
//  toolchain.h
//  
//
//  Created by Radzivon Bartoshyk on 21/09/2022.
//

#ifndef toolchain_h
#define toolchain_h

#include <stdio.h>
#include "mobi.h"

#define MOBI_TOOLCHAIN_ERROR 1
#define MOBI_TOOLCHAIN_SUCCESS 0

int dump_rawml_parts(const MOBIRawml *rawml, const char *fullpath);
int create_epub(const MOBIRawml *rawml, const char *fullpath);

#endif /* toolchain_h */
