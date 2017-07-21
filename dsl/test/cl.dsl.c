__kernel void generate (__global int *  a, unsigned long int len) {
    unsigned int i = get_global_id (0);

    if ((i < len)) {
        (a [i] = i);
    }
}
