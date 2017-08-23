import std.stdio;

import openclD._;
import std.file, std.stdio;
struct Test {
    int b;
    int i;
}


enum LEN = 10L;

void main () {
    auto map = new Kernel (
	    CLContext.instance.devices [0],
	    cast(string) read("cl_kernels/dsl.c"),
	    "map0")
	    
;

    auto array = new Vector!(Test) (new Test [10]);
    foreach (it ; 0 .. array.length) {
	array [it].b = cast (int) it;
    }

    writeln (array);
    map (10, 1, array, array.length);
    writeln (array);
    
}
