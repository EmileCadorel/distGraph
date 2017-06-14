import std.stdio;
import assign.admin;
import assign.graph.loader;
import assign.graph.FilterEdges;
import assign.graph.DistGraph;
import std.datetime;
import utils.Options;

void main (string [] args) {
    auto adm = new AssignAdmin (args);

    auto grp = Loader.load (Options ["-i"]);
    auto grp2 = grp.FilterEdges! (
	(EdgeD e) => e.src % 2 == 0
    );
    
    toFile (grp2.toDot.toString, "out.dot");
    delete adm;
}
