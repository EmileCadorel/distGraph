import std.stdio;

__skel generate (T, alias FN) (T [] a, ulong len) {
    auto i = get_global_id (0);
    if (i < len)
	a [i] = FN (i);
}

__skel zip (T, T2, T3, alias FN) (T[] a, T2 [] b, T3 [] c, ulong len) {
    auto i = get_global_id (0);
    if (i < len)
	c [i] = FN (a [i], b [i]);
}

enum LEN = 10L;

void main () {
    auto genI = #[0].generate!(int, (i) => i);
    auto genF = #[0].generate!(float, (i) => i);

    auto zipF = #[0].zip!(int, float, float, (a, b) => a * b);
    
    auto a = new Vector!(int) (LEN);
    auto b = new Vector!(float) (LEN);
    auto c = new Vector!(float) (LEN);
    
    genI (10, 1, a, LEN);
    genF (10, 1, b, LEN);
    
    zipF (10, 1, a, b, c, LEN);
        
    writeln (a);
    writeln (b);
    writeln (c);
    
}
