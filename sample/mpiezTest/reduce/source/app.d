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

    auto begin = Clock.currTime;    
    auto grp = DistGraphLoader.open (Options ["-i"], nb);

    auto pgraph = grp.JoinVertices! (
	(VertexD v, int deg) => new DegVertex (v.data, 1.0, deg)
    ) (grp.outDegree);
    
    auto ranked = pgraph.Pregel ! (
    	(DegVertex v, float msg) => new DegVertex (v.data, 0.15 + 0.85 * msg, v.deg),	
    	(EdgeTriplet!(DegVertex, EdgeD) e) => Iterator!float (e.dst.id, e.src.rank  / e.src.deg),	
    	(float a, float b) => a + b
    ) (1.0, iter);

    if (id == 0) {
	writeln ("Temps : ", Clock.currTime - begin);
    }

    auto file = File (format("out%d.dot", id), "w+");
    file.writeln (ranked.toDot ());
    file.close ();    
}

void AggregateMessage (int id, int total) {
    import std.random, std.typecons;
    
    if (!Options.active ("-i"))	assert (false, "On a besion d'un fichier d'entrée");
    auto grp = DistGraphLoader.open (Options ["-i"]);

    auto aged = grp.MapVertices!((VertexD v) => new DstVertex (v.data, uniform (0, 100)));
    
    auto olderFollowers = aged.MapReduceTriplets! (
	(EdgeTriplet!(DstVertex, EdgeD) trp) {
	    if (trp.src.dst > trp.dst.dst)
		return iterator (trp.dst.id, tuple (1, trp.src.dst));
	    else return Iterator!(Tuple!(int, float)).empty;
	},
	(Tuple!(int, float) a, Tuple!(int, float) b) => tuple(a [0] + b[0], a[1] + b[1])
    );

    auto avg = olderFollowers.Map!(
	(Tuple!(int, float) a) => a [1] / a [0]
    );
    
    writeln (avg);    
}   

void shortPath (int id, int total) {
    auto nb = 2;
    if (Options.active ("-n"))	nb = to!(int) (Options ["-n"]);
    if (Options.active ("-l"))	DistGraphLoader.lambda = to!float (Options ["-l"]);
    if (!Options.active ("-i"))	assert (false, "On a besion d'un fichier d'entrée");
    
    auto begin = Clock.currTime;    
    auto grp = DistGraphLoader.open (Options ["-i"], nb);
    
    auto vprog = (DstVertex v, float nDist) =>
	new DstVertex (v.data, min (v.dst, nDist));    
    
    auto sendMsg = (EdgeTriplet!(DstVertex, EdgeD) triplet) {
	if (triplet.src.dst + 1 < triplet.dst.dst) 
	    return Iterator!float (triplet.dst.id, triplet.src.dst + 1);
	else return Iterator!(float).empty;
    };

    auto mergeMsg = (float a, float b) => min (a, b);

    import std.random;
    auto sourceId = grp.total - 1;    
    auto initialGraph = grp.MapVertices! (
	(VertexD v) {
	    if (v.id == sourceId) {
		return new DstVertex (v.data, 0.0f);
	    } 
	    return new DstVertex (v.data, float.infinity);
	}
    );
    
    auto sssp = initialGraph.Pregel !(vprog, sendMsg, mergeMsg) (float.infinity);
    
    if (id == 0) {
	writeln ("Temps : ", Clock.currTime - begin);
    }
    
    auto file = File (format("out%d.dot", id), "w+");
    file.writeln (sssp.toDot ());
    file.close ();    
    
}

void test (int id, int total) {
    auto nb = 2;
    if (Options.active ("-n"))	nb = to!(int) (Options ["-n"]);
    if (Options.active ("-l"))	DistGraphLoader.lambda = to!float (Options ["-l"]);
    if (!Options.active ("-i"))	assert (false, "On a besion d'un fichier d'entrée");

    auto grp = DistGraphLoader.open (Options ["-i"], nb);

    foreach (it ; 0 .. 100000)
	auto deg = grp.outDegreeTest ();
    //syncWriteln (deg);
}

void master (int id, int total) {
    if (Options.active ("--short"))
	shortPath (id, total);
    else if (Options.active ("--test"))
	test (id, total);
    else if (Options.active ("--old"))
	AggregateMessage (id, total);
    else pageRank (id, total);
    
}

int main (string [] args) {
    auto adm = new Admin!(master) (args);
    adm.finalize ();
    return 0;
}
