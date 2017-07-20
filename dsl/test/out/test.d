import std.stdio;

import system.Kernel, system.CLContext, data.Vector;
import std.file, std.stdio;
struct Test {
    int a;
}


enum LEN = 10L;

void main () {
    auto k = new Kernel (
	    CLContext.instance.devices [0],
	    cast(string) read("cl.dsl.c"),
	    "generate")
	    
;
    auto a = new Vector!(Test) (LEN);
    
    k (10, 1, a, LEN);
        
    writeln (a);    
}
