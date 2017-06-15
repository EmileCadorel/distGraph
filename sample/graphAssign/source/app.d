import std.stdio;
import assign.admin;
import assign.graph.loader;
import assign.graph.JoinVertices;
import assign.graph.MapReduceTriplets;
import assign.graph.DistGraph;
import std.datetime;
import utils.Options;

class VertexDeg : VertexD {

    int deg;
    this (ulong id, int deg) {
	super (id);
	this.deg = deg;
    }
    
}

void main (string [] args) {
    auto adm = new AssignAdmin (args);

    auto grp = Loader.load (Options ["-i"]);
    auto res = grp.MapReduceTriplets! (
	(VertexD src, VertexD dst, EdgeD edge) => iterator (src.id, 1),
	(int a, int b) => a + b
    );

    auto grp2 = grp.JoinVertices!(
	(VertexD v, int i) => new VertexDeg (v.id, i)
    ) (res);
        
    toFile (grp2.toDot.toString, "out.dot");
    delete adm;
}
