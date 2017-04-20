module test;
import std.stdio;
import mpiez.admin;
import utils.Options;
import std.conv, std.math, std.algorithm;
import skeleton.Compose;
import dgraph.DistGraphLoader;
import std.datetime;
import std.format;

class DstVertex : VertexD {

    float dst;
    
    this (Vertex v) {
	super (v);
	this.dst = float.infinity;
    }

    this (Vertex v, float dst) {
	super (v);
	this.dst = dst;
    }

    override string toString () {
	return format ("\t\t%d[label=\"%d, %f\"];", this.id, this.id, dst);
    }
    
}


void master (int id, int total) {
    auto nb = 2;
    if (Options.active ("-n"))
	nb = to!(int) (Options ["-n"]);
    if (Options.active ("-l"))
	DistGraphLoader.lambda = to!float (Options ["-l"]);
    if (!Options.active ("-i"))
	assert (false, "On a besion d'un fichier d'entrée");

    auto grp = DistGraphLoader.open (Options ["-i"], nb);

    auto vprog = (DstVertex v, float nDist) =>
	new DstVertex (v.data, min (v.dst, nDist));    

    auto sendMsg = (EdgeTriplet!(DstVertex, EdgeD) triplet) {
	if (triplet.src.dst + 1 < triplet.dst.dst) 
	    return Iterator!float (triplet.dst.id, triplet.src.dst + 1);
	else return EmptyIterator!float;
    };

    auto mergeMsg = (float a, float b) => min (a, b);

    auto begin = Clock.currTime;
    auto sourceId = grp.total - 1;
    auto initialGraph = grp.MapVertices! (
	(VertexD v) {
	    if (v.id == sourceId) return new DstVertex (v.data, 0.0f);
	    else return new DstVertex (v.data, float.infinity);
	}
    );

    auto sssp = initialGraph.Pregel !(vprog, sendMsg, mergeMsg) (float.infinity, 100);
    auto end = Clock.currTime;

    if (id == 0) {
	writeln ("Temps : ", end - begin);
    }
    
    auto file = File (format ("out%d.dot", id), "w+");
    file.writeln (sssp.toDot ().toString);
    file.close ();
    
}

int main (string [] args) {
    auto adm = new Admin!(master) (args);
    adm.finalize ();
    return 0;
}
