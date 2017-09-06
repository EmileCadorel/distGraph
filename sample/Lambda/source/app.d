import std.stdio;
import distGraph.assign._;
import CL = openclD._;

enum n = 100;

void main(string [] args) {
    auto adm = new AssignAdmin (args);
    
    auto a = new DistArray!ulong (1000);
    auto res = a.Init!(#(i) => 1);
    auto res2 = res.Reduce!(#(a, b) => a + b);
    
    writeln (res2);

    adm.end ();
}
