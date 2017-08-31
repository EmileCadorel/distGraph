import std.stdio;
import distGraph.assign._;
import CL = openclD._;

enum n = 100;

struct Test {
    long a;
    long b;
}

void main(string [] args) {
    auto adm = new AssignAdmin (args);
    
    auto a = new DistArray!Test (n);
    auto res = a.Init!(#(i) => Test (i, -i));
    writeln (res.toString);

    adm.end ();
}
