module test;
import std.stdio;
import mpiez.admin;
import utils.Options;
import std.conv, std.math, std.algorithm;
import skeleton.Compose;
import dgraph.DistGraphLoader;
import std.datetime;

class VertexDD (T) : VertexD  {

    private T _val;
    
    this (Vertex v) {
	super (v);	
    }

    ref T val () {
	return this._val;
    }

    override string toString () {
	import std.format;
	return format ("\t\t%d[label=\"%d%s\"];", id(), id(), to!string(this._val));
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
    
    auto grp2 = grp.MapVertices!(
	(VertexD v) {	    
	    auto res = new VertexDD!string (v.data);
	    res.val = to!string (cast (char) (res.id % 26 + 'a'));
	    return res;
	}
    );

    auto grp3 = grp2.MapEdges!(
	(EdgeD e) {
	    return new EdgeD (Edge (e.dst, e.src, e.color));	    
	}
    );
    
    grp3 = grp3.FilterEdges!((EdgeD e) => e.dst != 6 && e.src != 6).
	FilterVertices!((VertexDD!string v) => v.val > "h");
	
    
    auto file = File ("bout" ~ to!string (id) ~ ".dot", "w+");
    file.write (grp.toDot ().toString);
    file.close ();

    file = File ("out" ~ to!string (id) ~ ".dot", "w+");
    file.write (grp3.toDot ().toString);
    file.close ();
}

int main (string [] args) {
    auto adm = new Admin!(master) (args);
    adm.finalize ();
    return 0;
}
