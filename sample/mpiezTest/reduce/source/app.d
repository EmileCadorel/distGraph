module test;
import std.stdio;
import mpiez.admin;
import utils.Options;
import std.traits;
import utils.FunctionTable;
import std.conv, std.math, std.algorithm;
import skeleton.Compose;
import dgraph.DistGraphLoader;

void master (int id, int total) {
    auto a = Generate! ((ulong i) => 1UL).run (100000);
    auto b = Generate!((ulong i) => 1UL).run (100000);
    auto c = Zip! (2,(ulong i, ulong j) => i + j).run (a, b);
    auto d = Reduce!((ulong i, ulong j) => i + j).run (c);
    if (id == 0)
	writeln (d);
    
}

int main (string [] args) {
    auto adm = new Admin!(master) (args);
    adm.finalize ();
    return 0;
}
