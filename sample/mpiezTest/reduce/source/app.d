module test;
import std.stdio;
import mpiez.admin;
import utils.Options;
import std.traits;
import utils.FunctionTable;
import std.conv, std.math, std.algorithm;
import skeleton.Reduce, skeleton.Map;
import skeleton.Generate;

struct Test {
    long a;
    long b;
}

Test hehe (Test a, Test b) {
    return Test (a.a + b.a, max (a.b, b.b));
}

Test one (ulong i, ulong N) {
    return Test (i, N);
}

Test test (Test a) {
    if (a.a > sqrt (cast (float) a.b))
	return a;
    else return Test (0, 0);
}

void master (int id, int total) {
    import std.random;
    auto len = to!(int) (Options ["-u"]);
    auto nb = 2;
    if (Options.active ("-n"))
	nb = to!(int) (Options ["-n"]);
    
    for (int i = 0; i < 1000; i++) {
	writeln ("Loop ", i);
	auto array = Generate!(one).run (len, nb);
	writeln (Reduce!(hehe).run (array, nb));        
    }    

}

int main (string [] args) {
    auto adm = new Admin!(master) (args);
    adm.finalize ();
    writeln ("End");
    return 0;
}
