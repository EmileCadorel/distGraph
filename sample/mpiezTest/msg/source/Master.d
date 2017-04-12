import Proto;
import std.stdio;
import std.string, std.conv;
import mpiez.Message, mpiez.Process;

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
	while (nb < this._proto.total - 1) {
	    int type;
	    receive (
		(int procId, byte) {
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
		},
		(int procId, ulong [] vertices) {
		    computeState (procId, vertices);		    
		},
		(int, Edge [] edges) {
		    foreach (it ; edges) {
			this._current.addEdge (it);
		    }
		},
		(int, byte) {
		    // Master a recu une requete de fin
		    nb ++;
		}, MPI_COMM_WORLD,
		[1, 3, 5, 6]
	    );
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
    

    private void writeGraph () {
	auto file = File ("out.dot", "w+");	
	file.write (this._current.toDot (null, true).toString ());
	file.close ();

    }
    
        
}
