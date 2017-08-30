import std.stdio;

struct Test {
    int b;
    int i;
}

__skel map (T, alias FUN) (T [] a, ulong size) {
    auto i = get_global_id (0);
    if (i < size)
	a [i] = FUN (a [i]);
}

enum LEN = 10L;

void main () {
    alias lmbd = #(a, b) => writeln (a + b);
    lmbd.call (12, 10);
}
