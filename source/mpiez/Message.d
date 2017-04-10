module mpiez.Message;
import mpi.mpi;
import mpiez.ezBase, mpiez.ezArray, mpiez.ezList;

class Message (int N, T ...) {
    
    private MPI_Status _status;

    private MPI_Comm _comm;
    
    void opCall (int procId, T params) {
	this._send (procId, params);
    }
    
    void receive  (int procId, ref T params) {
	this._recv (procId, params);
    }

    void sendReceive (int procId, T params, ref T params2) {
	this._sendRecv (procId, params, params2);
    }

    void sendReceive (int procId1, int procId2, T params, ref T params2) {
	this._sendRecv (procId1, procId2, params, params2);
    }

    void sendRecveiveReplace (int procId, ref T params) {
	this._sendRecvReplace (procId, params);
    }

    void sendRecveiveReplace (int procId1, int procId2, ref T params) {
	this._sendRecvReplace (procId1, procId2, params);
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

	void _send (T) (int procId, T param) {
	    send (procId, N, param, this._comm);
	}

	void _recv (T, TNext ...) (int procId, ref T param, ref TNext params) {
	    recv (procId, N, param, this._status, this._comm);
	    this._recv (procId, params);
	}

	void _recv (T) (int procId, ref T param) {
	    recv (procId, N, param, this._status, this._comm);
	}

	void _sendRecv (T, TNext ...) (int procId, T param, TNext params, ref T param2, ref TNext params2) {
	    sendRecv (procId, procId, N, param, param2, this._status, this._comm);
	    this._sendRecv (procId, params, params2);
	}

	void _sendRecv (T) (int procId, T param, ref T param2) {
	    sendRecv (procId, procId, N, param, param2, this._status, this._comm);
	}

	void _sendRecv (T, TNext ...) (int procId, int procId2, T param, TNext params, ref T param2, ref TNext params2) {
	    sendRecv (procId, procId2, N, param, param2, this._status, this._comm);
	    this._sendRecv (procId, params, params2);
	}

	void _sendRecv (T) (int procId, int procId2, T param, ref T param2) {
	    sendRecv (procId, procId2, N, param, param2, this._status, this._comm);
	}
	
	void _sendRecvReplace (T, TNext...) (int procId, ref T param, ref TNext params) {
	    sendRecvReplace (procId, procId, N, param, this._status, this._comm);
	    this._sendRecvReplace (procId, params);
	}

	void _sendRecvReplace (T) (int procId, ref T param) {
	    sendRecvReplace (procId, procId, N, param, this._status, this._comm);
	}

	void _sendRecvReplace (T, TNext...) (int procId, int procId2, ref T param, ref TNext params) {
	    sendRecvReplace (procId, procId2, N, param, this._status, this._comm);
	    this._sendRecvReplace (procId, params);
	}

	void _sendRecvReplace (T) (int procId, int procId2, ref T param) {
	    sendRecvReplace (procId, procId2, N, param, this._status, this._comm);
	}
	       	
    }
    
}
