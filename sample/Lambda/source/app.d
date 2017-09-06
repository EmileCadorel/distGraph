import std.stdio;
import distGraph.assign._;
import CL = openclD._;

enum n = 100;

void main(string [] args) {
    auto adm = new AssignAdmin (args);
    
    auto a = new DistArray!ulong (100);
    auto res = a.Init!(#(i) => i);
    res = res.Map!(#(i, v) => i + v);
    
    writeln (res.toString);

    adm.end ();
}
