import std.stdio;
import openclD._;
import std.file, std.stdio;
import distGraph.assign._;
import CL = openclD._;

enum n = 100;

struct Test {
    long a;
    long b;
}

void main() {
    auto a = new DistArray!Test (n);
    auto res = a.Init!(Lambda!((i)=> Test (i, -i)
, "(i)=> Test (i, -i)
")
);
    writeln (res.local);    
}
