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
    auto map = #[0].map! (Test, (a) => Test (a.i, a.b));

    auto array = new Vector!(Test) (new Test [10]);
    foreach (it ; 0 .. array.length) {
	array [it].b = cast (int) it;
    }

    writeln (array);
    map (10, 1, array, array.length);
    writeln (array);
    
}
