import std.stdio;
import assign.admin;
import assign.graph.loader;
import assign.graph.MapVertices;
import assign.graph.DistGraph;
import std.datetime;
import utils.Options;

class VertexDist : VertexD {

    float dist;
    this (ulong id, float dist) {
	super (id);
	this.dist = dist;
    }
}


void main (string [] args) {
    auto adm = new AssignAdmin (args);

    auto grp = Loader.load (Options ["-i"]);
    auto grp2 = grp.MapVertices! (
	(VertexD vd) {
	    if (vd.id == 7) 
		return new VertexDist (vd.id, 0.0f);
	    else
		return new VertexDist (vd.id, float.infinity);
	}
    );
    
    toFile (grp2.toDot.toString, "out.dot");
    delete adm;
}
