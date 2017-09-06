import std.stdio;
import dsl._;
import CL = openclD._;

__skel reduce (T, alias FUN) (T [] a, T [] b, ulong count, __loc T[] partialSum) {
    auto t = get_local_id (0), start = 2 * get_group_id (0) * get_local_size (0);
    if (start + t < count)
	partialSum [t] = a [start + t];
    else partialSum [t] = 0;

    if (start + get_local_size (0) < count)
	partialSum [get_local_size (0) + t] = a [start + get_local_size (0) + t];
    else partialSum [get_local_size (0) + t] = 0;

    for (auto stride = get_local_size (0) ; stride >= 1; stride >>= 1) {
	barrier (CLK_LOCAL_MEM_FENCE);
	if (t < stride)
	    partialSum [t] = FUN (partialSum [t], partialSum [stride + t]);
    }

    if (t == 0)
	b [get_group_id (0)] = partialSum [0];
}

enum LEN = 10L;

void main () {
    auto reduce = #reduce!(int, (a, b) => a + b);
    auto b = new Vector!(int) (1);
    auto a = new Vector!(int) (32);

    foreach (it ; 0 .. a.length)
	a [it] = 1;

    auto local = 32; //CL.CLContext.instance.devices[0].blockSize;    
    
    reduce.callWithLocalSize (1, local, 2 * local * int.sizeof, a, b, a.length); 
    writeln (b);
}
