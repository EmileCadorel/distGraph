module mpiez.Message;
import mpi.mpi;
import mpiez.ezBase;
import std.typecons;

class Message (int N, T ...) {
    
    private MPI_Status _status;

    private MPI_Comm _comm;

    this (MPI_Comm comm = MPI_COMM_WORLD) {
	this._comm = comm;
    }
    
    void opCall (int procId, T params) {
	this._send (procId, params);
    }
    
    void receive (ref T params) {
	this._recvAny (params);
    }

    void receive (int procId, void function(T params) callBack) {
	Tuple!T tuple;
	this._recv (procId, tuple.expand);
	callBack (tuple.expand);
    }

    void receive (int procId, void delegate(T params) callBack) {
	Tuple!T tuple;
	this._recv (procId, tuple.expand);
	callBack (tuple.expand);
    }
    
    void receive  (int procId, ref T params) {
	this._recv (procId, params);
    }

    ref MPI_Comm comm () {
	return this._comm;
    }    

    const (MPI_Status) status () {
	return this._status;
    }
    
    immutable const (int) value () {
	return N;
    }

    private {
	
	void _send (T, TNext ...) (int procId, T param, TNext params) {
	    send (procId, N, param, this._comm);
	    this._send (procId, params);
	}

	void _send (T : U*, U, T2 : ulong, TNext ...) (int procId, T param, T2 size, TNext params) {
	    send (procId, N, param, size, this._comm);
	    this._send (procId, params);
	}	
	
	void _send () (int procId) {}
	
	void _recv (T, TNext ...) (int procId, ref T param, ref TNext params) {
	    recv (procId, N, param, this._status, this._comm);
	    this._recv (procId, params);
	}

	void _recv (T : U*, U, T2, TNext ...) (int procId, ref T param, ref T2 size, ref TNext params) {
	    recv (procId, N, param, size, this._status, this._comm);
	    this._recv (procId, params);
	}
	
	void _recv () (int procId) {}
	
	void _recvAny (T, TNext ...) (ref T param, ref TNext params) {
	    recv (N, param, this._status, this._comm);
	    this._recvAny (params);
	}

	void _recvAny (T) (ref T param) {
	    recv (N, param, this._status, this._comm);
	}
			       	
    }
    
}
