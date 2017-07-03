import std.stdio;
import assign.admin;
import assign.graph.loader;
import assign.graph.JoinVertices;
import assign.graph.MapVertices;
import assign.graph.MapReduceTriplets;
import assign.graph.FilterEdges;
import assign.graph.InitVertices;
import assign.graph.Pregel;
import assign.graph.DistGraph;
import assign.data.AssocArray;
import std.datetime, std.algorithm;
import utils.Options, std.conv;

class DstVertex : VertexD {

    float [] dst;
    ulong current;
    
    this (ulong id, float [] dst) {
	super (id);
	this.dst = dst;
    }

    override string toString () {
	import std.format;
	return format ("%s", to!string (dst));
    }
    
}

void main (string [] args) {
    try {
	auto adm = new AssignAdmin (args);
	auto begin = Loader.load (Options ["-i"]);
	ulong nbVerts = begin.nbVerts;

	auto beginT = Clock.currTime;	
	auto grp = begin.InitVertices! (
	    (VertexD v, ulong nb) => new DstVertex (v.id, new float [nb])
	) (nbVerts);
	
	foreach (it ; 0 .. nbVerts) {
	    writeln ("VERT : ", it);	    
	    grp = grp.InitVertices! (
		(DstVertex v, ulong val) {
		    v.current = val;
		    if (v.id == val) {
			v.dst [val] = 0.0f;			
		    } else v.dst [val] = float.infinity;
		    return v;
		}
	    ) (it);
	    
	    grp = grp.Pregel! (
		(DstVertex v, float nDist) {
		    v.dst [v.current] = min (v.dst [v.current], nDist);
		    return v;
		},
		(DstVertex src, DstVertex dst, EdgeD edge) {
		    if (src.dst[src.current] + 1 < dst.dst[src.current])
			return iterator (dst.id, src.dst[src.current] + 1);
		    else return Iterator!(float).empty;
		}, 
		(float a, float b) => min (a, b)
	    );
	    writeln ("FIN VERT : ", it);	    
	}

	writeln ("Total : ", Clock.currTime - beginT);
	auto str = grp.toDot.toString;
	toFile (str, "out.dot");    

	adm.end ();
    } catch (Exception e) {
	writeln (e);
	stdout.flush ();
    }
}    
