import std.stdio;

import system.Kernel, system.CLContext, data.Vector;
struct Test {
    int a;
    int b;
}



void main () {
    auto a = new Kernel (
	    CLContext.instance.devices [0],
	    "cl.dsl.c",
	    what.str);
	    
;
}
