#include "cl_kernels/structs.h"

__kernel void map0 (__global struct Test *  a, unsigned long int size) {
    unsigned int i = get_global_id (0);

    if ((i < size)) {
        (a [i] = (struct Test) { .b = a [i].i, .i = a [i].b});
    }
}
