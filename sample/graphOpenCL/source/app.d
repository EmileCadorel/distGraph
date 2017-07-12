import std.stdio;
import assign.admin;
import assign.graph.loader;
import assign.graph.InitVertices;
import assign.graph.DistGraph;
import utils.Options;

struct Dst {

    ulong id;
    float dst;
    
    this (ulong id, float dst) {
	this.id = id;
	this.dst = dst;
    }
    

}

void main (string [] args) {
    auto adm = new AssignAdmin (args);
    auto begin = Loader.load (Options ["-i"]);

    auto grp = begin.InitVertices! (
	"Dst (a.id, 0.0f) : Dst (a.id, float.infinity)", 
	(a, b) => (a.id == b) ? Dst (a.id, 0.0f) : Dst (a.id, float.infinity)	
    ) (0);

    grp.toDot.toString.toFile ("out.dot");
    adm.end ();
}
