import std.stdio;

struct Test {
    int a;
    int b;
}

kern generate (int [] a, ulong len) {
    //auto i = get_global_id (0);
    //if (i < len)
	a [len] = len;
}

void main () {
    auto a = #[0].vecadd;
}
