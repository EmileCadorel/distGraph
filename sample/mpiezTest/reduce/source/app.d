module test;
import std.stdio;
import mpiez.admin;
import utils.Options;
import std.traits;
import utils.FunctionTable;
import std.conv, std.math, std.algorithm;
import skeleton.Reduce, skeleton.Map;
import skeleton.Generate;


void master (int id, int total) {
    import std.random;
    auto len = to!(int) (Options ["-u"]);
    auto nb = 2;
    if (Options.active ("-n"))
	nb = to!(int) (Options ["-n"]);
    
    for (int i = 0; i < 1000; i++) {
	writeln ("Loop ", i);
	auto array = Generate!((ulong i) => cast (int) i).run (len, nb);
	writeln (Reduce!((int a, int b) => a + b).run (array, nb));        
    }    

}

int main (string [] args) {
    auto adm = new Admin!(master) (args);
    adm.finalize ();
    return 0;
}
