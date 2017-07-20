import std.stdio;

import system.Kernel, system.CLContext, data.Vector;
import std.file, std.stdio;


enum LEN = 10L;

void main () {
    auto k = new Kernel (
	    CLContext.instance.devices [0],
	    cast(string) read("cl.dsl.c"),
	    "generate")
	    
;
    auto k2 = new Kernel (
	    CLContext.instance.devices [0],
	    cast(string) read("cl.dsl.c"),
	    "vecadd")
	    
;
    auto a = new Vector!(int) (LEN);
    auto b = new Vector!(int) (LEN);
    auto c = new Vector!(int) (LEN);
    
    k (10, 1, a, LEN);
    k (10, 1, b, LEN);

    k2 (10, 1, a, b, c, LEN);
        
    writeln (c);    
}
