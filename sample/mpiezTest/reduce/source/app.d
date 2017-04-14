module test;
import std.stdio;
import mpiez.admin;
import utils.Options;
import std.traits;
import utils.FunctionTable;
import std.conv;
import skeleton.Reduce, skeleton.Map;
import skeleton.Generate;

struct Test {
    long a;
    long b;
}

Test sum (Test a, Test b) {
    return Test (a.a + b.a, a.b + b.b);
}

Test one (ulong i, ulong N) {
    return Test (N, -N);
}

void master (int id, int total) {
    import std.random;
    auto len = to!(int) (Options ["-l"]);
    auto nb = 2;
    if (Options.active ("-n"))
	nb = to!(int) (Options ["-n"]);
    
    auto array = Generate!(one).run (len, nb);
    writeln (array);
    writeln (Reduce!(sum).run (array, nb));        
}

void main (string [] args) {
    auto adm = new Admin!(master) (args);
    adm.finalize ();
}
