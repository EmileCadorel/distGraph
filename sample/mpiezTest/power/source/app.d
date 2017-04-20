import std.stdio;
import mpiez.admin;
import utils.Options;
import std.conv, std.math, std.algorithm;
import skeleton.Compose;
import dgraph.DistGraphLoader;
import std.datetime;
import std.format;

class DegVertex : VertexD {

    float rank;
    float old;
    int deg;
    
    this (DegVertex deg) {
	super (deg.data);
	this.rank = deg.rank;
	this.old = deg.old;
	this.deg = deg.deg;
    }

    this (Vertex v) {
	super (v);
	this.rank = 1.0;
	this.deg = 0;
	this.old = 1.0;
    }
    
    this (Vertex v, int deg, float rank, float old) {
	super (v);
	this.deg = deg;
	this.old = old;
	this.rank = rank;
    }

    override string toString () {
	return format ("\t\t%d[label=\"%d, %f, %d\"];", this.id, this.id, rank, deg);
    }
    
}


void master (int id, int total) {
    auto nb = 2;
    if (Options.active ("-n"))	nb = to!(int) (Options ["-n"]);
    if (Options.active ("-l"))	DistGraphLoader.lambda = to!float (Options ["-l"]);
    if (!Options.active ("-i"))	assert (false, "On a besion d'un fichier d'entrée");
    
    auto grp = DistGraphLoader.open (Options ["-i"], nb);
    auto pgraph = grp.JoinVertices! (
	(VertexD v, int deg) => new DegVertex (v.data, deg, 1.0, 1.0)
    ) (grp.outDegreeTest);

    auto sssp = pgraph.PowerGraph ! (
	(EdgeTriplet!(DegVertex, EdgeD) e) {
	    return Iterator!float (e.dst.id, e.src.rank / e.src.deg);
	},
	(float a, float b) => a + b,
	(DegVertex v, float a) => new DegVertex (v.data, v.deg, 0.15 + 0.85 * a, v.rank),
	(EdgeTriplet!(DegVertex, EdgeD) e) {
	    return Iterator!bool (e.src.id, abs (e.src.rank - e.src.old) > float.epsilon);
	}
    ) (10);

    
    auto file = File (format ("out%d.dot", id), "w+");
    file.writeln (sssp.toDot ());
    file.close ();
    
}

int main (string [] args) {
    auto adm = new Admin!(master) (args);
    adm.finalize ();
    return 0;
}
