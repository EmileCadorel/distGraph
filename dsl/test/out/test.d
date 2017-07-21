import std.stdio;


import system.Kernel, system.CLContext, data.Vector;
import std.file, std.stdio;


enum LEN = 10L;

void main () {
    auto genI = new Kernel (
	    CLContext.instance.devices [0],
	    cast(string) read("cl.dsl.c"),
	    "generate0")
	    
;
    auto genF = new Kernel (
	    CLContext.instance.devices [0],
	    cast(string) read("cl.dsl.c"),
	    "generate1")
	    
;
    
    auto map = new Kernel (
	    CLContext.instance.devices [0],
	    cast(string) read("cl.dsl.c"),
	    "map0")
	    
;
    auto mpf = new Kernel (
	    CLContext.instance.devices [0],
	    cast(string) read("cl.dsl.c"),
	    "map1")
	    
;
    
    auto a = new Vector!(int) (LEN);
    auto b = new Vector!(float) (LEN);
    
    genI (10, 1, a, LEN);
    genF (10, 1, b, LEN);
    
    map (10, 1, a, LEN);
    mpf (10, 1, b, LEN);
        
    writeln (a);
    writeln (b);    
}
