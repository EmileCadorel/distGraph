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

    private GraphProto _graphProto;
    
    private DistGraph _dist;    
    
    private MPI_Comm _childs;
    
    this (Proto p, GraphProto gp, string filename, ulong size, MPI_Comm childs) {
	this._proto = p;
	this._filename = filename;
	this._current = new Graph (size);
	this._childs = childs;
	this._graphProto = gp;
	this._dist = new DistGraph (0);
    }

    Graph graph () {
	return this._current;
    }

    DistGraph dgraph () {
	return this._dist;
    }
    
    private void _next () {
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
		    if (perc > 50) {
			this._currentPercent = perc;
			//	writeln (this._currentPercent, "/", 100);
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
	    int type; byte useless;
	    auto status = this._proto.probe (MPI_ANY_SOURCE, MPI_ANY_TAG, this._childs);
	    if (status.MPI_TAG == 1) {
		this._proto.request.receive (status.MPI_SOURCE, useless, this._childs);
		this._next ();
		if (this._read) {
		    Serializer!(Edge*) serial;
		    serial.value = &this._toSend;
		    this._proto.edge (status.MPI_SOURCE, serial.ptr, Edge.sizeof, this._childs);
		    // Master a envoye un arete a  procId
		} else {
		    this._proto.edge (status.MPI_SOURCE, null, 0, this._childs);
		    // Master a envoye un message vide a procId
		}		    
	    }  else if (status.MPI_TAG == 3) {
		ulong [] vertices;
		this._proto.state.receive (status.MPI_SOURCE, vertices, this._childs);
		computeState (status.MPI_SOURCE, vertices);
	    } else if (status.MPI_TAG == 5) {
		Edge [] edges;
		this._proto.putState.receive (status.MPI_SOURCE, edges, this._childs);
		disrtribute (edges);
	    } else if (status.MPI_TAG == 6) {
		this._proto.end.receive (status.MPI_SOURCE, useless, this._childs);
		nb ++;
	    } else assert (false, "Pas prevu ca");
	}
	
    }

    private void disrtribute (Edge [] _edges) {
	Array!(Vertex) [] verts = new Array!Vertex [this._current.partitions.length];
	Array!(Edge) [] edges = new Array!Edge [this._current.partitions.length];

	foreach (it ; _edges) {
	    this._current.addEdge (it);
	    verts [it.color].insertBack (this._current.getVertex (it.src));
	    verts [it.color].insertBack (this._current.getVertex (it.dst));
	    edges [it.color].insertBack (it);
	}
		
	foreach (it ; verts [0]) this._dist.addVertex (it);
	foreach (it ; edges [0]) this._dist.addEdge (it);
	
	foreach (vt ; 1 .. verts.length) {
	    long [] retVerts;
	    foreach (it ; 0 .. verts [vt].length) {
		retVerts ~= verts [vt][it].serialize ();
	    }
		    
	    this._graphProto.edge (cast (int) vt, cast (ubyte*) retVerts.ptr, retVerts.length * long.sizeof, edges [vt].array ());
	}		
    }

    private void computeState (int procId, ulong [] vertices) {
	long [] retVerts;
	foreach (it ; 0 .. vertices.length) {
	    retVerts ~= this._current.getVertex (vertices [it]).serialize ();
	}

	this._proto.getState (procId, cast(ubyte*) retVerts.ptr, retVerts.length * long.sizeof , this._current.partitions, this._childs);
    }
    
    private void writeGraph () {
	auto filename = Options ["-o"];
	if (filename is null)
	    filename = "out.dot";
	auto file = File (filename, "w+");	
	file.write (this._current.toDot (null, true).toString ());
	file.close ();

    }

}
