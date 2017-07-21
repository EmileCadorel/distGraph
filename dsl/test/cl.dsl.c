__kernel void generate0 (__global int *  a, unsigned long int len) {
    unsigned int i = get_global_id (0);

    if ((i < len)) {
        (a [i] = i);
    }
}
__kernel void generate1 (__global float *  a, unsigned long int len) {
    unsigned int i = get_global_id (0);

    if ((i < len)) {
        (a [i] = (i * 1.0));
    }
}
__kernel void map0 (__global int *  a, unsigned long int len) {
    unsigned int i = get_global_id (0);

    if ((i < len)) {
        (a [i] = (a [i] + 1));
    }
}
__kernel void map1 (__global float *  a, unsigned long int len) {
    unsigned int i = get_global_id (0);

    if ((i < len)) {
        (a [i] = (a [i] * 3.4));
    }
}
