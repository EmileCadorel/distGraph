import std.stdio;
import mpiez.admin;
import utils.Options;
import std.conv, std.math, std.algorithm;
import skeleton.Compose;
import dgraph.DistGraphLoader;
import std.datetime;
import std.format, std.random;

class DstVertex : VertexD {
    float dst;
    float old;
    
    this (DstVertex deg) {
	super (deg.data);
	this.dst = deg.dst;
	this.old = deg.old;
    }

    this (Vertex v) {
	super (v);
	assert (false);
    }
    
    this (Vertex v, float dst, float old) {
	super (v);
	this.dst = dst;
	this.old = old;
    }

    override string toString () {
	return format ("\t\t%d[label=\"%d, %f, %f\"];", this.id, this.id, dst, old);
    }    
}


class DegVertex : VertexD {

    float rank, old;
    int deg;
    
    this (Vertex v) {
	super (v);
	this.rank = 1.0;
	this.deg = 0;
	this.old = 1.0;
    }

    this (DegVertex other) {
	super (other.data);
	this.rank = other.rank;
	this.deg = other.deg;
	this.old = other.old;
    }
    
    this (Vertex v, int deg, float rank, float old) {
	super (v);
	this.deg = deg;
	this.rank = rank;
	this.old = old;
    }

    override string toString () {
	return format ("\t\t%d[label=\"%d, %f, %d\"];", this.id, this.id, rank, deg);
    }
    
}



void shortPath (int id, int total) {
   auto nb = 2;
    if (Options.active ("-n"))	nb = to!(int) (Options ["-n"]);
    if (Options.active ("-l"))	DistGraphLoader.lambda = to!float (Options ["-l"]);
    if (!Options.active ("-i"))	assert (false, "On a besion d'un fichier d'entrée");
    
    auto grp = DistGraphLoader.open (Options ["-i"], nb);

    auto begin1 = Clock.currTime;
    foreach (sourceId ; 0 .. grp.total) {
	auto begin = Clock.currTime ();
	auto pgraph = grp.MapVertices! (
	    (VertexD v) => v.id == sourceId ? new DstVertex (v.data, 0.0, 1.0) : new DstVertex (v.data, float.infinity, float.infinity)
	);
	
	auto sssp = pgraph.PowerGraph ! (
	    (EdgeTriplet!(DstVertex, EdgeD) e) => iterator (e.dst.id, e.src.dst + 1),
	    (float a, float b) => min (a, b),
	    (DstVertex v, float a) {
		if (a < v.dst) 
		    return new DstVertex (v.data, a, v.dst);
		else return new DstVertex (v.data, v.dst, a);
	    },
	    (EdgeTriplet!(DstVertex, EdgeD) e) => iterator (e.src.id, abs (e.src.dst - e.src.old) > float.epsilon ||
							    e.src.dst == float.infinity)	    
	) (10);
	
	auto end = Clock.currTime ();
	if (id == 0)
	    writeln (end - begin, " cumul ", end - begin1);
    }
}


void pageRank (int id, int total) {
   auto nb = 2;
    if (Options.active ("-n"))	nb = to!(int) (Options ["-n"]);
    if (Options.active ("-l"))	DistGraphLoader.lambda = to!float (Options ["-l"]);
    if (!Options.active ("-i"))	assert (false, "On a besion d'un fichier d'entrée");
    
    auto grp = DistGraphLoader.open (Options ["-i"], nb);
    auto pgraph = grp.JoinVertices! (
	(VertexD v, int deg) => new DegVertex (v.data, deg, 1.0, 1.0)
    ) (grp.outDegreeTest);

    auto sssp = pgraph.PowerGraph ! (
	(EdgeTriplet!(DegVertex, EdgeD) e) => iterator (e.dst.id, e.src.rank / e.src.deg),	
	(float a, float b) => a + b,
	(DegVertex v, float a) => new DegVertex (v.data, v.deg, 0.15 + 0.85 * a, v.rank),						
	(EdgeTriplet!(DegVertex, EdgeD) e) => iterator (e.src.id, true)	
    ) (10);

    auto file = File (format("out%d.dot", id), "w+");
    file.writeln (sssp.toDot ());
    file.close ();
}

void master (int id, int total) {
    if (Options.active ("--short")) shortPath (id, total);
    else pageRank (id, total);
}

int main (string [] args) {
    auto adm = new Admin!(master) (args);
    adm.finalize ();
    return 0;
}
