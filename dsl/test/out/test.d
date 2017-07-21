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
    auto map = new Kernel (
	    CLContext.instance.devices [0],
	    cast(string) read("cl.dsl.c"),
	    "map")
	    
;
    
    auto a = new Vector!(int) (LEN);
    
    k (10, 1, a, LEN);
    map (10, 1, a, LEN);
        
    writeln (a);    
}
