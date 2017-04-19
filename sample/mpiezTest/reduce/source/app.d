module test;
import std.stdio;
import mpiez.admin;
import utils.Options;
import std.conv, std.math, std.algorithm;
import skeleton.Compose;
import dgraph.DistGraphLoader;
import std.datetime;

void master (int id, int total) {
    auto nb = 2;
    if (Options.active ("-n"))
	nb = to!(int) (Options ["-n"]);
    if (Options.active ("-l"))
	DistGraphLoader.lambda = to!float (Options ["-l"]);
    if (!Options.active ("-i"))
	assert (false, "On a besion d'un fichier d'entrée");

    auto grp = DistGraphLoader.open (Options ["-i"], nb);
    /*grp = Reverse (SubGraph!((Vertex v) => v.id % 2 == 0,
			     (Edge e) => e.src % 2 == e.dst % 2).run(grp)
			     );*/    

    auto begin = Clock.currTime;
    auto inDeg = inDegree (grp);
    auto outDeg = outDegree (grp);
    auto totalDeg = totalDegree (grp);
    
    syncWriteln (Clock.currTime - begin);
    
    auto maxIn = Reduce!((Ids!ulong a, Ids!ulong b) {
	    return a.value > b.value ? a : b;
	}) (inDeg);
    
    auto maxOut = Reduce!((Ids!ulong a, Ids!ulong b) {
	    return a.value > b.value ? a : b;
	}) (outDeg);
    
    auto maxTotal = Reduce!((Ids!ulong a, Ids!ulong b) {
	    return a.value > b.value ? a : b;
	}) (totalDeg);
    
    
    syncWriteln (
	"In (", maxIn.id, ", ", maxIn.value, ") ",
	"Out (", maxOut.id, ", ", maxOut.value, ") ",
	"Total (", maxTotal.id, ", ", maxTotal.value, ") "
    );
}

int main (string [] args) {
    auto adm = new Admin!(master) (args);
    adm.finalize ();
    return 0;
}
