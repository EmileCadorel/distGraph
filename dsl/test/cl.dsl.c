struct Test {
	int a;
};

__kernel void generate (__global struct Test *  a, unsigned long int len) {
    unsigned int i = get_global_id (0);

    if ((i < len)) {
        (a [i].a = i);
    }
}
