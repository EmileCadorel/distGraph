import std.stdio;
import openclD._;
import std.file, std.stdio;
import dsl._;
import CL = openclD._;


enum LEN = 10L;

void main () {
    auto reduce = new Kernel (
	    CLContext.instance.devices [0],
	    cast(string) read("/home/emile/libs/cl_kernels/dsl.c"),
	    "reduce0")
	    
;
    auto b = new Vector!(int) (1);
    auto a = new Vector!(int) (32);

    foreach (it ; 0 .. a.length)
	a [it] = 1;

    auto local = 32; //CL.CLContext.instance.devices[0].blockSize;    
    
    reduce.callWithLocalSize (1, local, 2 * local * int.sizeof, a, b, a.length); 
    writeln (b);
}
