module mpiez.Message;
import mpi.mpi;
import mpiez.ezBase;
import std.typecons;
import std.traits;

void receive (T ...) (T ops, MPI_Comm comm) {
    checkops (ops);
    MPI_Status status;
    MPI_Probe (MPI_ANY_SOURCE, MPI_ANY_TAG, comm, &status);
    int i = 1;
    foreach (it ; ops) {
	if (status.MPI_TAG == i) {
	    Tuple!(ParameterTypeTuple!(it) [1 .. $]) tuple;
	    __recv__ (status.MPI_SOURCE, status.MPI_TAG, tuple.expand, comm, status);
	    it (status.MPI_SOURCE, tuple.expand);
	}
	i++;
    }

}

void receive (int N, T ...) (T ops, MPI_Comm comm, int [N] ids) if (T.length == N) {
    checkops (ops);
    MPI_Status status;
    MPI_Probe (MPI_ANY_SOURCE, MPI_ANY_TAG, comm, &status);
    int i = 0;
    foreach (it ; ops) {
	if (status.MPI_TAG == ids [i]) {
	    Tuple!(ParameterTypeTuple!(it) [1 .. $]) tuple;
	    __recv__ (status.MPI_SOURCE, status.MPI_TAG, tuple.expand, comm, status);
	    it (status.MPI_SOURCE, tuple.expand);
	}
	i++;
    }

}

private void checkops(T...)(T ops)  {
    foreach (i, t1; T)  {
	static assert(isFunctionPointer!t1 || isDelegate!t1);
	alias a1 = ParameterTypeTuple!(t1);
	alias r1 = ReturnType!(t1);
	    
	static if (i < T.length - 1 && is(r1 == void)) {
	    static assert(a1.length >= 1 || !is(a1[0] == int),
			  "function with arguments " ~ a1.stringof ~
			  " occludes successive function");
	}
    }
}

private {
    void __recv__ (T, TNext ...) (int procId, int tag, ref T param, ref TNext params, MPI_Comm comm, MPI_Status status) {
	recv (procId, tag, param, status, comm);
	__recv__ (procId, tag, params, comm, status);
    }
    
    void __recv__ (T : U*, U, T2, TNext ...) (int procId, int tag, ref T param, ref T2 size, ref TNext params, MPI_Comm comm, MPI_Status status) {
	recv (procId, tag, param, size, status, comm);
	__recv__ (procId, tag, params, comm, status);
    }
    
    void __recv__ () (int, int, MPI_Comm, MPI_Status) {}
}

class Message (int N, T ...) {
    
    private MPI_Status _status;

    this () {
    }
    
    void opCall (int procId, T params, MPI_Comm comm = MPI_COMM_WORLD) {
	this._send (procId, params, comm);
    }
    
    void receive (ref T params, MPI_Comm comm = MPI_COMM_WORLD) {
	this._recvAny (params, comm);
    }

    void receive (void function(int id, T params) callBack, MPI_Comm comm = MPI_COMM_WORLD) {
	Tuple!T tuple;
	this._recv (MPI_ANY_SOURCE, tuple.expand, comm);
	callBack (this._status.MPI_SOURCE, tuple.expand);
    }
    
    void receive (void delegate(int id, T params) callBack, MPI_Comm comm = MPI_COMM_WORLD) {
	Tuple!T tuple;
	this._recv (MPI_ANY_SOURCE, tuple.expand, comm);
	callBack (this._status.MPI_SOURCE, tuple.expand);
    }

    void receive (int procId, void function(T params) callBack, MPI_Comm comm = MPI_COMM_WORLD) {
	Tuple!T tuple;
	this._recv (procId, tuple.expand, comm);
	callBack (tuple.expand);
    }

    void receive (int procId, void delegate(T params) callBack, MPI_Comm comm = MPI_COMM_WORLD) {
	Tuple!T tuple;
	this._recv (procId, tuple.expand, comm);
	callBack (tuple.expand);
    }
    
    void receive  (int procId, ref T params, MPI_Comm comm = MPI_COMM_WORLD) {
	this._recv (procId, params, comm);
    }
    
    const (MPI_Status) status () {
	return this._status;
    }
    
    immutable const (int) value () {
	return N;
    }

    private {
	
	void _send (T, TNext ...) (int procId, T param, TNext params, MPI_Comm comm) {
	    send (procId, N, param, comm);
	    this._send (procId, params, comm);
	}

	void _send (T : U*, U, T2 : ulong, TNext ...) (int procId, T param, T2 size, TNext params, MPI_Comm comm) {
	    send (procId, N, param, size, comm);
	    this._send (procId, params, comm);
	}	
	
	void _send () (int procId, MPI_Comm comm) {}
	
	void _recv (T, TNext ...) (int procId, ref T param, ref TNext params, MPI_Comm comm) {
	    recv (procId, N, param, this._status, comm);
	    this._recv (procId, params, comm);
	}

	void _recv (T : U*, U, T2, TNext ...) (int procId, ref T param, ref T2 size, ref TNext params, MPI_Comm comm) {
	    recv (procId, N, param, size, this._status, comm);
	    this._recv (procId, params, comm);
	}
	
	void _recv () (int procId, MPI_Comm comm) {}
	
	void _recvAny (T, TNext ...) (ref T param, ref TNext params, MPI_Comm comm) {
	    recv (N, param, this._status, comm);
	    this._recvAny (params, comm);
	}

	void _recvAny (T) (ref T param, MPI_Comm comm = MPI_COMM_WORLD) {
	    recv (N, param, this._status, comm);
	}
	
    }
    
}
