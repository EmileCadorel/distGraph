import Proto;
import std.stdio;
import std.string, std.conv;


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
	while (true) {
	    int type;
	    // Master attend un requete
	    this._proto.request.receive (-1, type);
	    auto procId = this._proto.request.status.MPI_SOURCE;
	    if (type == EDGE) {
		// Master a recu une requete d'arete de procId
		this._next ();
		if (this._read) {
		    Serializer!(Edge*) serial;
		    serial.value = &this._toSend;
		    this._proto.edge (procId, serial.ptr, Edge.sizeof);
		    // Master a envoye un arete a  procId
		} else {
		    this._proto.edge (procId, null, 0);
		    // Master a envoye un message vide a procId
		}
	    } else if (type == STATE) {
		ulong [] vertices;
		this._proto.state.receive (procId, vertices);
		computeState (procId, vertices);
	    } else if (type == PUT) {
		putState (procId);
	    } else if (type == END) {
		// Master a recu une requete de fin
		nb ++;
		if (nb == this._proto.total - 1) break;		
	    }
	}
	writeGraph ();
    }
      
    private void computeState (int procId, ulong [] vertices) {
	Vertex [] retVerts = new Vertex [vertices.length];
	foreach (it ; 0 .. vertices.length) {
	    retVerts [it] = this._current.getVertex (vertices [it]);
	}

	this._proto.getState (procId, retVerts, this._current.partitions);
    }

    private void putState (int procId) {
	Edge [] edges;
	this._proto.putState.receive (procId, edges);
	foreach (it ; edges) {
	    this._current.addEdge (it);
	}
    }
    

    private void writeGraph () {
	auto file = File ("out.dot", "w+");	
	file.write (this._current.toDot (null, true).toString ());
	file.close ();

    }
    
        
}
