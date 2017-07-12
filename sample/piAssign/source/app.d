import std.stdio;
import assign.data.Array;
import assign.skeleton.Init;
import assign.skeleton.Reduce;
import assign.graph.loader;
import assign.admin;
import std.datetime;
import std.conv;
import utils.Options;


enum n = 1_000_000;

void pi (string [] args) {    
    auto adm = new AssignAdmin (args);
    
    auto begin = Clock.currTime ();
    auto a = new DistArray!double (n);
    
    auto res = a.Init !(
	i => (4.0 / n) / ( 1.0 + (( i - 0.5 ) * (1.0 / n)) * (( i - 0.5 ) * (1.0 / n)))
    ).Reduce! (
	(a, b) => a + b
    );
    
    auto end = Clock.currTime ();
    
    writefln ("Pi = %.18f :(%s)", res, (end - begin).to!string);
    adm.end ();
}

void main (string [] args) {
    pi (args);
}
