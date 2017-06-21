import std.stdio;
import assign.admin;
import assign.graph.loader;
import assign.graph.JoinVertices;
import assign.graph.MapVertices;
import assign.graph.MapReduceTriplets;
import assign.graph.FilterEdges;
import assign.graph.Pregel;
import assign.graph.DistGraph;
import assign.data.AssocArray;
import std.datetime, std.algorithm;
import utils.Options, std.conv;

class DstVertex : VertexD {
    float dst;
    this (ulong id, float dst) {
	super (id);
	this.dst = dst;
    }    
}

void main (string [] args) {
    auto adm = new AssignAdmin (args);
    auto begin = Loader.load (Options ["-i"]);
    
    auto grp = begin.MapVertices! (
    	(VertexD v) {
    	    if (v.id == 0) return new DstVertex (v.id, 0.0f);
    	    else return new DstVertex (v.id, float.infinity);	    
    	}
    );
    
    auto grp2 = grp.Pregel! (
    	(DstVertex v, float nDist) {
    	    return new DstVertex (v.id, min (v.dst, nDist));
    	},
    	(DstVertex src, DstVertex dst, EdgeD edge) {
    	    if (src.dst + 1 < dst.dst) return iterator (dst.id, src.dst + 1);
    	    else return Iterator!(float).empty;
    	}, 
    	(float a, float b) => min (a, b)
    );

    auto str = grp2.toDot.toString;
    toFile (str, "out.dot");    

    adm.end ();
}
    
