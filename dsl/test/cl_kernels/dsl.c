__kernel void generate0 (__global int *  a, unsigned long int len) {
    unsigned int i = get_global_id (0);

    if ((i < len)) {
        (a [i] = i);
    }
}
__kernel void generate1 (__global float *  a, unsigned long int len) {
    unsigned int i = get_global_id (0);

    if ((i < len)) {
        (a [i] = i);
    }
}
__kernel void zip0 (__global int *  a, __global float *  b, __global float *  c, unsigned long int len) {
    unsigned int i = get_global_id (0);

    if ((i < len)) {
        (c [i] = (a [i] * b [i]));
    }
}
