module mpiez.Message;
import mpi.mpi;
import mpiez.ezBase;
import base = mpiez.ezBase;
import std.typecons;
import std.traits;

/++
 Réception d'un message et appel de la fonction associé
 Params:
 ops = une liste de fonctions
 comm = le communicateur 
+/
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

/++
 Réception d'un message et appel de la fonction associé
 Params:
 ops = une liste de fonctions
 comm = le communicateur 
 ids = un tableau des tag associé au fonction
+/
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


/++
 Vérifie que les fonctions sont appelable par un receive (T...) (T ops, )
 Params:
 T = une liste de fonctions
+/
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

/++
 Réception de tuple sur un communicateur.
+/
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

/++
 Classe utilisé dans une protocol pour communiquer entre plusieurs processus.
 Params:
 N = le tag du message (doît être unique dans un protocol)
 T = la liste des paramètre du message (des types que l'on peut envoyer)
+/
class Message (int N, T ...) {

    /++
     Le status du message (évolue à chaque récéption)
     +/
    private MPI_Status _status;

    this () {
    }

    /++
     Envoi du message
     Params:
     procId = la cible
     params = les données du messages
     comm = le communicateur à utiliser     
     +/
    void opCall (int procId, T params, MPI_Comm comm = MPI_COMM_WORLD) {
	this._send (procId, params, comm);
    }

    /++
     Envoi du message par ssend.
     Params:
     procId = la cible
     params = les données du messages
     comm = le communicateur à utiliser     
     +/
    void ssend (int procId, T params, MPI_Comm comm = MPI_COMM_WORLD) {
	this._ssend (procId, params, comm);
    }

    /++
     Réception du message.
     Params:
     params = les données à remplir.
     comm = le communicateur.
     +/
    void receive (ref T params, MPI_Comm comm = MPI_COMM_WORLD) {
	this._recvAny (params, comm);
    }

    /++
     Réception du message.
     Params:
     callBack = la fonction a appeler une fois les données reçu.
     comm = le communicateur.
     +/
    void receive (void function(int id, T params) callBack, MPI_Comm comm = MPI_COMM_WORLD) {
	Tuple!T tuple;
	this._recv (MPI_ANY_SOURCE, tuple.expand, comm);
	callBack (this._status.MPI_SOURCE, tuple.expand);
    }

    /++
     Réception du message.
     Params:
     callBack = la fonction a appeler une fois les données reçu.
     comm = le communicateur.
     +/
    void receive (void delegate(int id, T params) callBack, MPI_Comm comm = MPI_COMM_WORLD) {
	Tuple!T tuple;
	this._recv (MPI_ANY_SOURCE, tuple.expand, comm);
	callBack (this._status.MPI_SOURCE, tuple.expand);
    }
    
    /++
     Réception du message.
     Params:
     procId = le process source
     callBack = la fonction a appeler une fois les données reçu.
     comm = le communicateur.
     +/
    void receive (int procId, void function(T params) callBack, MPI_Comm comm = MPI_COMM_WORLD) {
	Tuple!T tuple;
	this._recv (procId, tuple.expand, comm);
	callBack (tuple.expand);
    }

    /++
     Réception du message.
     Params:
     procId = le process source
     callBack = la fonction a appeler une fois les données reçu.
     comm = le communicateur.
     +/    
    void receive (int procId, void delegate(T params) callBack, MPI_Comm comm = MPI_COMM_WORLD) {
	Tuple!T tuple;
	this._recv (procId, tuple.expand, comm);
	callBack (tuple.expand);
    }
    
    /++
     Réception du message.
     Params:
     procId = le process source
     params = les données à remplir
     comm = le communicateur.
     +/
    void receive  (int procId, ref T params, MPI_Comm comm = MPI_COMM_WORLD) {
	this._recv (procId, params, comm);
    }

    /++
     Récupère le status de la dernière récéption.
     +/
    const (MPI_Status) status () {
	return this._status;
    }

    /++
     alias TAG.
     +/
    immutable const (int) value () {
	return N;
    }

    /++
     Returns: le tag du message (N).
     +/
    const (int) TAG () {
	return N;
    }

    /++
     Toutes les fonctions suivantes servent à l'envoi et la récéption de tuple sur un communicateur.
     +/
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

	void _ssend (T, TNext ...) (int procId, T param, TNext params, MPI_Comm comm) {
	    base.ssend (procId, N, param, comm);
	    this._ssend (procId, params, comm);
	}

	void _ssend (T : U*, U, T2 : ulong, TNext ...) (int procId, T param, T2 size, TNext params, MPI_Comm comm) {
	    base.ssend (procId, N, param, size, comm);
	    this._ssend (procId, params, comm);
	}	
	
	void _ssend () (int procId, MPI_Comm comm) {}
	
	
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
