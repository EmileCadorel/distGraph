import std.stdio;

fn vecadd (ulong [] a, ulong [] b, ulong len) {
    auto i = get_global_id (0);
    if (i < len)
	c [i] = a[i] + b[i];
}

fn generate (ulong [] a, ulong len) {
    auto i = get_global_id (0);
    if (i < len)
	a [i] = i;
}

void main () {
    ulong [] a = new ulong [100];
    ulong [] b = new ulong [100];
    
    generate (a, a.length);
    generate (b, b.length);
    
    auto a = vecadd (a, b, a.length);
}
