module assign.graph.loader;
import assign.graph.DistGraph;
import utils.Singleton;
import assign.cpu;
import std.string, std.stdio;
import std.conv, std.concurrency;

alias Loader = LoaderS.instance;
class LoaderS {

    private int _currentPercent = 0;
    private ulong _length = 0;
    
    private bool next (File file, ref Edge edge) {
	while (true) {
	    auto line = file.readln ();
	    if (line is null) return false;
	    line = line.stripLeft;
	    if (line.length > 0 && line [0] != '#') {
		auto nodes = line.split;
		edge.src = Vertex (to!ulong (nodes [0]));
		edge.dst = Vertex (to!ulong (nodes [1]));
		auto pos = file.tell ();
		auto perc = to!int (to!float (pos) / to!float(this._length) * 100.);
		if (perc > this._currentPercent) {
		    this._currentPercent = perc;
		    writef ("\rChargement du graphe %s>%s%d%c",
			    leftJustify ("[", this._currentPercent, '='),
			    rightJustify ("]", 100 - this._currentPercent, ' '),
			    this._currentPercent, '%');
		    stdout.flush;
		}
		return true;
	    }
	}
    }    

    private File open (string filename) {
	auto file = File (filename, "r");
	file.seek (0, SEEK_END);
	this._length = file.tell ();
	file.seek (0, SEEK_SET);
	return file;
    }
    
    static void worker (Tid owner, shared DistGraph!(VertexD, EdgeD) dg) {
	auto grp = cast (DistGraph!(VertexD, EdgeD)) dg;
	auto end = false;
	while (!end) {
	    receive (
		(Edge e) {
		    grp.addEdge (e);
		},
		(bool) => end = true	
	    );	    
	}
	send (owner, true);
    }
       
    DistGraph!(VertexD, EdgeD) load (string filename) {
	auto dg = new DistGraph!(VertexD, EdgeD) ();
	auto file = open (filename);
	Edge edge;
	auto nb = SystemInfo.cpusInfo.length;
	//auto spawned = spawn (&worker, thisTid, cast (shared DistGraph!(VertexD, EdgeD)) dg);
	auto i = 0;
	while (next (file, edge)) {
	    // En parallèle ça plante, à debugger
	    //spawned.send (edge);
	    dg.addEdge (edge);	    
	}

	/*send (spawned, true);	
	  receiveOnly!(bool);	*/
	
	return dg;
    }

    mixin Singleton;
    
}
