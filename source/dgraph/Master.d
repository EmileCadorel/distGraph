module dgraph.Master;
import std.stdio;
import std.string, std.conv;
import mpiez.Message, mpiez.Process;
import utils.Options;
import dgraph.DistGraphLoader;
import dgraph.Graph;
import dgraph.DistGraph;
import std.container, std.array;

class Master {
    
    private Proto _proto;    

    private Edge _toSend;

    private File _file;

    private string _filename;

    private Graph _current;
    
    private bool _read;

    private ulong _length;

    private ulong _currentPercent;
    
    private DistGraph _dist;    
    
    
    this (Proto p, string filename, ulong size) {
	this._proto = p;
	this._filename = filename;
	this._current = new Graph (size);
	this._dist = new DistGraph (p.id, size);
    }

    Graph graph () {
	return this._current;
    }

    DistGraph dgraph () {
	return this._dist;
    }
    
    private void _next () {
	import std.string;
	this._read = false;
	while (true) {
	    auto line = this._file.readln ();
	    if (line !is null) {
		line = line.stripLeft;
		if (line.length > 0 && line [0] != '#') {
		    auto nodes = line.split;
		    this._toSend.src = to!ulong (nodes [0]);
		    this._toSend.dst = to!ulong (nodes [1]);
		    this._read = true;
		    auto pos = this._file.tell ();
		    auto perc = to!int (to!float (pos) / to!float(this._length) * 100.);
		    if (perc > this._currentPercent) {
			this._currentPercent = perc;
			writef ("\rChargement du graphe %s>%s%d%c",
				leftJustify ("[", this._currentPercent, '='),
				rightJustify ("]", 100 - this._currentPercent, ' '),
				this._currentPercent, '%');
			stdout.flush;
		    }
		    break;
		}
	    } else break;	    
	}
    }

    private auto _open (string filename) {
	auto file = File (filename, "r");
	file.seek (0, SEEK_END);
	this._length = file.tell ();
	file.seek (0, SEEK_SET);
	return file;
    }
    

    void run (ulong total) {
	this._file = this._open (this._filename);
	int nb = 0;
	while (nb < total) {	    
	    int type; ulong useless; byte uselessb;
	    auto status = this._proto.probe (MPI_ANY_SOURCE, MPI_ANY_TAG);
	    if (status.MPI_TAG == 1) {
		this._proto.request.receive (status.MPI_SOURCE, uselessb);
		this._next ();
		if (this._read) {
		    Serializer!(Edge*) serial;
		    serial.value = &this._toSend;
		    this._proto.edge (status.MPI_SOURCE, serial.ptr, Edge.sizeof);
		    // Master a envoye un arete a  procId
		} else {
		    this._proto.edge (status.MPI_SOURCE, null, 0);
		    // Master a envoye un message vide a procId
		}		    
	    }  else if (status.MPI_TAG == 3) {
		ulong [] vertices;
		this._proto.state.receive (status.MPI_SOURCE, vertices);
		computeState (status.MPI_SOURCE, vertices);
	    } else if (status.MPI_TAG == 5) {
		Edge [] edges;
		this._proto.putState.receive (status.MPI_SOURCE, edges);
		foreach (it ; edges)
		    this._current.addEdge (it);
	    } else if (status.MPI_TAG == 6) {
		this._proto.end.receive (status.MPI_SOURCE, useless);
		nb ++;
	    } else assert (false, "Pas prevu ca");
	}

	disrtribute ();		
	writeln ("");
    }

    private void disrtribute () {
	foreach (it; 0 .. this._current.vertices.length) {
	    if (it == 0) {
		foreach (ref vt ; this._current.vertices [it])
		    this._dist.addVertex (vt);
	    } else {
		long [] retVert;
		foreach (ref vt ; this._current.vertices [it]) retVert ~= vt.serialize ();
		this._proto.graphVert (cast (int) it, retVert);
	    }
	}

	foreach (it ; 0 .. this._current.edges.length) {
	    if (it == 0) {
		this._dist.edges = this._current.edges [it].array ();
	    } else {
		this._proto.graphEdge (cast (int) it, this._current.edges [it].array ());
	    }
	}

	foreach (it ; 0 .. this._proto.total) {
	    this._proto.end (cast (int) it, this._current.verticesTotal.length);	    
	}
	
	this._dist.total = this._current.verticesTotal.length;
    }

    private void computeState (int procId, ulong [] vertices) {
	long [] retVerts;
	foreach (it ; 0 .. vertices.length) {
	    retVerts ~= this._current.getVertex (vertices [it]).serialize ();
	}

	this._proto.getState (procId, cast(ubyte*) retVerts.ptr, retVerts.length * long.sizeof , this._current.partitions);
    }

}
