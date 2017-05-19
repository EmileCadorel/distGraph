import std.stdio;
import assign.data.Array;
import assign.skeleton.Init;
import assign.skeleton.Reduce;
import assign.admin;
import std.datetime;
import std.parallelism, std.range;
import std.algorithm.iteration : map;
import std.conv;

enum n = 1_000_000;

void main (string [] args) {
    auto adm = new AssignAdmin (args);
    scope (exit) delete adm;
    
    auto a = new DistArray!double (n);
    a.Init!(
    	(ulong i) {
	    return (1.0 / n) / ( 1.0 + (( i - 0.5 ) * (1.0 / n)) * (( i - 0.5 ) * (1.0 / n))) ;
    	}
    );
    
    auto res = a.Reduce! (
    	(double a, double b) => a + b
    );
    
    writeln ("Pi = ", 4 * res);        
}
