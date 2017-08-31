import std.stdio;
import distGraph.assign._;
import CL = openclD._;

enum n = 100;

void main() {
    auto a = new DistArray!int (n);
    auto res = a.Init!(CL.Lambda !(i => i, "i => -i"));
    writeln (res.local);    
}
