import std.stdio;
import distGraph.assign._;
import std.datetime, std.algorithm;
import distGraph.utils._, std.conv;

struct DstVertex {

    ulong id;
    float [] dst;
    ulong current;
    
    this (ulong id, float [] dst) {
	this.id = (id);
	this.dst = dst;
    }    
}

void main (string [] args) {
    try {
	auto adm = new AssignAdmin (args);
	auto begin = Loader.load (Options ["-i"]);
	ulong nbVerts = begin.nbVerts;

	auto beginT = Clock.currTime;	
	auto grp = begin.InitVertices! (
	    (VertexD v, ulong nb) => DstVertex (v.id, new float [1])
	) (nbVerts);
	
	foreach (it ; 0 .. 1) {
	    writeln ("VERT : ", it);	    
	    grp = grp.InitVertices! (
		(v, val) {
		    v.current = val;
		    if (v.id == val) {
			v.dst [val] = 0.0f;			
		    } else v.dst [val] = float.infinity;
		    return v;
		}
	    ) (it);
	    
	    grp = grp.Pregel! (
		(v, nDist) {
		    v.dst [v.current] = min (v.dst [v.current], nDist);
		    return v;
		},
		(src, dst, edge) {
		    if (src.dst[src.current] + 1 < dst.dst[src.current])
			return iterator (dst.id, src.dst[src.current] + 1);
		    else return Iterator!(float).empty;
		}, 
		(a, b) => min (a, b)
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
