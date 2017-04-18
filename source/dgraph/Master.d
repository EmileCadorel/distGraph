module dgraph.Master;
import std.stdio;
import std.string, std.conv;
import mpiez.Message, mpiez.Process;
import utils.Options;
import dgraph.DistGraphLoader;
import dgraph.Graph;

class Master {
    
    private Proto _proto;    

    private Edge _toSend;

    private File _file;

    private string _filename;

    private Graph _current;
    
    private bool _read; 
    
    this (Proto p, string filename, ulong size) {
	this._proto = p;
	this._filename = filename;
	this._current = new Graph (size);
    }

    Graph graph () {
	return this._current;
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
		    break;
		}
	    } else break;	    
	}
    }
    
    void run () {
	this._file = File (this._filename, "r");
	int nb = 0;
	while (nb < this._proto.total - 1) {
	    int type; byte useless;
	    auto status = this._proto.probe ();
	    if (status.MPI_TAG == 1) {
		this._proto.request.receive (status.MPI_SOURCE, useless);
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
		foreach (it ; edges) {
		    this._current.addEdge (it);
		}
	    } else if (status.MPI_TAG == 6) {
		this._proto.end.receive (status.MPI_SOURCE, useless);
		nb ++;
	    } else assert (false, "Pas prevu ca");
	}
	writeGraph ();
    }

    private void computeState (int procId, ulong [] vertices) {
	long [] retVerts;
	foreach (it ; 0 .. vertices.length) {
	    retVerts ~= this._current.getVertex (vertices [it]).serialize ();
	}

	this._proto.getState (procId, cast(ubyte*) retVerts.ptr, retVerts.length * long.sizeof , this._current.partitions);
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
