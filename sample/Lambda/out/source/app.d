import std.stdio;
import openclD._;
import std.file, std.stdio;
import distGraph.assign._;
import CL = openclD._;

enum n = 1000;

void main() {
    auto a = new DistArray!double (n);
    auto res = a.Init!(Lambda!((i)=> i
, "(i)=> i
")
);
    writeln (res.local);    
}
