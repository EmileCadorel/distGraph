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


class DegVertex : VertexD {

    float rank;
    int deg;
    
    this (Vertex v) {
	super (v);
	this.rank = 1.0;
	this.deg = 0;
    }

    this (Vertex v, float rank, int deg) {
	super (v);
	this.deg = deg;
	this.rank = rank;
    }

    override string toString () {
	return format ("\t\t%d[label=\"%d, %f, %d\"];", this.id, this.id, rank, deg);
    }
    
}




void pageRank (int id, int total) {
    auto nb = 2, iter = 10;
    if (Options.active ("-n")) nb = to!(int) (Options ["-n"]);
    if (Options.active ("-l"))	DistGraphLoader.lambda = to!float (Options ["-l"]);
    if (!Options.active ("-i"))	assert (false, "On a besion d'un fichier d'entrée");
    if (Options.active ("--it")) iter = to!int (Options ["--it"]);
    
    auto grp = DistGraphLoader.open (Options ["-i"], nb);
    auto pgraph = grp.JoinVertices! ((VertexD v, int deg) => new DegVertex (v.data, 1.0, deg)) (grp.outDegreeTest);

    auto ranked = pgraph.Pregel ! (
	(DegVertex v, float msg) => new DegVertex (v.data, 0.15 + 0.85 * msg, v.deg),	
	(EdgeTriplet!(DegVertex, EdgeD) e) => Iterator!float (e.dst.id, e.src.rank  / e.src.deg),	
	(float a, float b) => a + b,
	true
    ) (1.0, iter);

    auto file = File (format("out%d.dot", id), "w+");
    file.writeln (ranked.toDot ());
    file.close ();
    
}


void shortPath (int id, int total) {
   auto nb = 2;
    if (Options.active ("-n"))	nb = to!(int) (Options ["-n"]);
    if (Options.active ("-l"))	DistGraphLoader.lambda = to!float (Options ["-l"]);
    if (!Options.active ("-i"))	assert (false, "On a besion d'un fichier d'entrée");

    auto grp = DistGraphLoader.open (Options ["-i"], nb);

    auto vprog = (DstVertex v, float nDist) =>
	new DstVertex (v.data, min (v.dst, nDist));    

    auto sendMsg = (EdgeTriplet!(DstVertex, EdgeD) triplet) {
	if (triplet.src.dst + 1 < triplet.dst.dst) 
	    return Iterator!float (triplet.dst.id, triplet.src.dst + 1);
	else return EmptyIterator!float;
    };

    auto mergeMsg = (float a, float b) => min (a, b);

    import std.random;
    auto begin1 = Clock.currTime;    

    auto sourceId = uniform (0, grp.total - 1);
    broadcast (0, sourceId, MPI_COMM_WORLD);
    syncWriteln (sourceId);
    
    auto begin = Clock.currTime;    
    auto initialGraph = grp.MapVertices! (
	(VertexD v) {
	    if (v.id == sourceId) return new DstVertex (v.data, 0.0f);
	    else return new DstVertex (v.data, float.infinity);
	}
    );
    
    auto sssp = initialGraph.Pregel !(vprog, sendMsg, mergeMsg, true) (float.infinity);
    auto end = Clock.currTime;
        
    if (id == 0) {
	writeln ("Temps : ", end - begin, ' ', sourceId,  " / ", grp.total, " cumul : ", end - begin1);
    }

    auto file = File (format ("out%d.dot", id), "w+");
    file.writeln (sssp.toDot ());
    file.close ();
    
}


void master (int id, int total) {
    if (Options.active ("--short"))
	shortPath (id, total);
    else
	pageRank (id, total);
    
}

int main (string [] args) {
    auto adm = new Admin!(master) (args);
    adm.finalize ();
    return 0;
}
