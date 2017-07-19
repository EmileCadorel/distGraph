import std.stdio;

import system.Kernel, system.CLContext, data.Vector;
import std.file, std.stdio;
struct Test {
    int a;
    int b;
}


void main () {
    auto a = new Kernel (
	    CLContext.instance.devices [0],
	    cast(string) read("cl.dsl.c"),
	    "vecadd")
	    
;
}
