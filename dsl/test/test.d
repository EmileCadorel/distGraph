import std.stdio;

struct Test {
    int a;
}

__kernel generate (Test [] a, ulong len) {
    auto i = get_global_id (0);
    if (i < len)
	a [i].a = i;
}

enum LEN = 10L;

void main () {
    auto k = #[0].generate;
    auto a = new Vector!(Test) (LEN);
    
    k (10, 1, a, LEN);
        
    writeln (a);    
}
