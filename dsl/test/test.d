import std.stdio;

__kernel generate (int [] a, ulong len) {
    auto i = get_global_id (0);
    if (i < len)
	a [i] = i;
}

__kernel vecadd (int [] a, int [] b, int [] c, ulong len) {
    auto i = get_global_id (0);    
    if (i < len)
	c [i] = a [i] + b [i];
}

enum LEN = 10L;

void main () {
    auto k = #[0].generate;
    auto k2 = #[0].vecadd;
    auto a = new Vector!(int) (LEN);
    auto b = new Vector!(int) (LEN);
    auto c = new Vector!(int) (LEN);
    
    k (10, 1, a, LEN);
    k (10, 1, b, LEN);

    k2 (10, 1, a, b, c, LEN);
        
    writeln (c);    
}
