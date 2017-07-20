__kernel void generate (__global int *  a, unsigned long int len) {
    unsigned int i = get_global_id (0);

    if ((i < len)) {
        (a [i] = i);
    }
}
__kernel void vecadd (__global int *  a, __global int *  b, __global int *  c, unsigned long int len) {
    unsigned int i = get_global_id (0);

    if ((i < len)) {
        (c [i] = (a [i] + b [i]));
    }
}
