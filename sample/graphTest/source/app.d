import std.stdio;
import dgraph.GraphLoader;
import std.algorithm, std.conv;

void main (string [] args) {
    if (args.length >= 4) {
	auto a = GraphLoader.fromEdges (args [1], to!ulong (args[2]), to!float (args [3]));
	auto filename = "out.dot";
	if (args.length >= 5) filename = args [4];

	auto score = 0;
	foreach (vt ; a.vertices) {
	    if (vt && vt.partitions.length > 0) {
		write (vt.id, "-> [");
		if (vt.partitions.length > 1)
		    score++;
		foreach (pt; vt.partitions)
		    write (pt, pt !is vt.partitions [$ - 1] ? ", " : "");
		writeln ("]");
	    }
	}

	writeln ("Ratio : ", cast (float) score / cast (float) a.vertices.length, " -> ",
		 score, "/", a.vertices.length);
	
	auto file = File (filename, "w");	
	file.write (a.toDot (null, true).toString ());
	file.close ();
	
	file = File ("normal_" ~ filename, "w");	
	file.write (a.toDot ().toString ());
	file.close ();
	
    } else throw new Exception ("./usage file lambda [out]");
}
