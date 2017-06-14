import std.stdio;
import assign.data.Array;
import assign.skeleton.Map;
import assign.skeleton.Reduce;
import assign.graph.loader;
import assign.admin;
import std.datetime;
import std.conv;
import utils.Options;
import app2 = app2;

enum n = 1_000_000;

void pi (string [] args) {    
    auto adm = new AssignAdmin (args);
    scope (exit) delete adm;
    
    auto begin = Clock.currTime ();
    auto a = new DistArray!double (n);

    
    auto res = a.Map !(
	(size_t i, double it) {
	    return (1.0 / n) / ( 1.0 + (( i - 0.5 ) * (1.0 / n)) * (( i - 0.5 ) * (1.0 / n)));
	}
    ).Reduce! (
    	(double a, double b) => a + b
    );
    
    auto end = Clock.currTime ();

    writefln ("Pi = %.18f :(%s)", 4.0 * res, (end - begin).to!string);            
}

void main (string [] args) {
    auto adm = new AssignAdmin (args);
    
    auto grp = Loader.load (Options ["-i"]);
    toFile (grp.toDot ().toString, "out.dot");

    delete adm;
}
