import std.stdio;


__kernel generate (int [] a, ulong len) {
    auto i = get_global_id (0);
    if (i < len)
	a [i] = i;
}

__skel map (T, alias FN) (T [] a, ulong len) {
    auto i = get_global_id (0);
    if (i < len) 
	a [i] = FN (a[i]);    
}

enum LEN = 10L;

void main () {
    auto k = #[0].generate;
    auto map = #[0].map!(int, (a) => a + 1);
    
    auto a = new Vector!(int) (LEN);
    
    k (10, 1, a, LEN);
    map (10, 1, a, LEN);
        
    writeln (a);    
}
