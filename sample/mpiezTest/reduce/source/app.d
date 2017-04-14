module test;
import std.stdio;
import mpiez.admin;
import utils.Options;
import std.traits;
import utils.FunctionTable;
import std.conv;
import skeleton.Reduce;

struct Test {
    int a;
    int b;
}

Test sum (Test a, Test b) {
    return Test (a.a + b.a, a.b + b.b);
}

void master (int id, int total) {
    import std.random;
    auto len = to!(int) (Options ["-l"]);
    auto nb = 2;
    if (Options.active ("-n"))
	nb = to!(int) (Options ["-n"]);
    auto array = new Test [len];    
    foreach (it ; 0 .. len)
	array [it] = Test (it + 1, it - 1);
    writeln (Reduce!(sum, Test).run (array, nb));    
}

void main (string [] args) {
    auto adm = new Admin!(master) (args);
    adm.finalize ();
}
