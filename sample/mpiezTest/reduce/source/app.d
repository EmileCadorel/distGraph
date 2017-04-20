module test;
import std.stdio;
import mpiez.admin;
import utils.Options;
import std.conv, std.math, std.algorithm;
import skeleton.Compose;
import dgraph.DistGraphLoader;
import std.datetime;
import std.format;
		     
void master (int id, int total) {
    auto nb = 2;
    if (Options.active ("-n"))
	nb = to!(int) (Options ["-n"]);
    if (Options.active ("-l"))
	DistGraphLoader.lambda = to!float (Options ["-l"]);
    if (!Options.active ("-i"))
	assert (false, "On a besion d'un fichier d'entrée");

    auto grp = DistGraphLoader.open (Options ["-i"], nb);

    auto msgFun = (EdgeTriplet! (VertexD, EdgeD) triplet) =>
	Iterator!(ulong) (triplet.dst.id, 1);
    
    auto reduceMsg = (ulong left, ulong right) => left + right;

    foreach (it ; 0 .. 1000) {
	auto begin = Clock.currTime;
	auto deg = grp.inDegree ();
	auto end = Clock.currTime;
	auto res = grp.MapReduceTriplets!(msgFun, reduceMsg);
	auto end2 = Clock.currTime ();
	if (id == 0) {
	    auto t1 = end - begin, t2 = end2 - end;
	    writeln (t1, t1 > t2 ? " > " : " < ", t2);
	}
    }
    
    
    auto file = File ("out" ~ to!string (id) ~ ".dot", "w+");
    file.write (grp.toDot ().toString);
    file.close ();
}

int main (string [] args) {
    auto adm = new Admin!(master) (args);
    adm.finalize ();
    return 0;
}
