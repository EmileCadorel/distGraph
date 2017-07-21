import std.stdio;


__skel generate (T, alias FN) (T [] a, ulong len) {
    auto i = get_global_id (0);
    if (i < len)
	a [i] = FN (i);
}

__skel map (T, alias FN) (T [] a, ulong len) {
    auto i = get_global_id (0);    
    if (i < len) 
	a [i] = FN (a[i]);    
}

enum LEN = 10L;

void main () {
    auto genI = #[0].generate!(int, (i) => i);
    auto genF = #[0].generate!(float, (i) => i * 1.0);
    
    auto map = #[0].map!(int, (a) => a + 1);
    auto mpf = #[0].map!(float, (a) => a * 3.4);
    
    auto a = new Vector!(int) (LEN);
    auto b = new Vector!(float) (LEN);
    
    genI (10, 1, a, LEN);
    genF (10, 1, b, LEN);
    
    map (10, 1, a, LEN);
    mpf (10, 1, b, LEN);
        
    writeln (a);
    writeln (b);    
}
