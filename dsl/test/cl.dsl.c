struct Test {
	int a;
	int b;
};

__kernel void vecadd (__global ulong*  a, __global ulong*  b, __global ulong*  c, ulong len) {
    auto i = get_global_id (0);

    if ((i < len)) {
        (c [i] = (a [i] + b [i]));
    }
}
__kernel void generate (__global Test*  a, ulong len) {
    auto i = get_global_id (0);

    if ((i < len)) {
        (a [i] = i);
    }
}
