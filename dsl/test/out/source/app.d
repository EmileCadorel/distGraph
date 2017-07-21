import std.stdio;

import system.Kernel, system.CLContext, data.Vector;
import std.file, std.stdio;


enum LEN = 10L;

void main () {
    auto genI = new Kernel (
	    CLContext.instance.devices [0],
	    cast(string) read("cl_kernels/dsl.c"),
	    "generate0")
	    
;
    auto genF = new Kernel (
	    CLContext.instance.devices [0],
	    cast(string) read("cl_kernels/dsl.c"),
	    "generate1")
	    
;

    auto zipF = new Kernel (
	    CLContext.instance.devices [0],
	    cast(string) read("cl_kernels/dsl.c"),
	    "zip0")
	    
;
    
    auto a = new Vector!(int) (LEN);
    auto b = new Vector!(float) (LEN);
    auto c = new Vector!(float) (LEN);
    
    genI (10, 1, a, LEN);
    genF (10, 1, b, LEN);
    
    zipF (10, 1, a, b, c, LEN);
        
    writeln (a);
    writeln (b);
    writeln (c);
    
}
