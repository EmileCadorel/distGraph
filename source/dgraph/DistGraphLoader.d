module dgraph.DistGraphLoader;
import utils.Singleton;
import std.stdio;
import dgraph.Graph;
public import dgraph.Edge, dgraph.Vertex;
import std.string, std.conv;
import std.container, std.algorithm;
import dgraph.Partition;
import mpiez.Message, mpiez.Process;
import dgraph.Master, dgraph.Slave;
import skeleton.Register;
import mpiez.admin;
import utils.Options;
public import dgraph.DistGraph;

enum WINDOW_SIZE = 1;

enum EDGE = 0;
enum STATE = 1;
enum PUT = 2; 
enum END = 3;

union Serializer (T : U*, U) {
    T value;
    ubyte * ptr;
}

class Proto : Protocol {
    this (int id, int total) {
	super (id, total);
	this.request = new Message!(1, byte);
	this.edge = new Message!(2, ubyte*, ulong);
	this.state = new Message!(3, ulong []);
	this.getState = new Message!(4, ubyte*, ulong, ulong[]);
	this.putState = new Message!(5, Edge []);
	this.graphEdge = new Message!(7, Edge[]);
	this.graphVert = new Message!(8, long []);
	this.end = new Message!(6, ulong);
    }

    // Id de la requete
    Message!(1, byte) request;

    // Donnees, taille des donnees
    Message!(2, ubyte*, ulong) edge;

    // Les identifiants des vertices
    Message!(3, ulong []) state;

    // l'etat courant du graphe, (Vertex, partitions) 
    Message!(4, ubyte*, ulong, ulong []) getState;

    // Met a jour le graphe
    Message!(5, Edge[]) putState;

    Message!(7, Edge []) graphEdge;

    Message!(8, long []) graphVert;
    
    Message!(6, ulong) end;
}


class DistGraphLoaderS {

    private float _lambda = 1.8;

    ref float lambda () {
	return this._lambda;
    }

    DistGraph!(VertexD, EdgeD) open (string filename, int nbWorker = 2) {	
	auto info = Proto.commInfo (MPI_COMM_WORLD);
	nbWorker = info.total < nbWorker ? info.total : nbWorker;
	auto proto = new Proto (info.id, info.total);
	if (info.id == 0) {
	    auto master = new Master (proto, filename, info.total);
	    master.run (nbWorker - 1);	    
	    return master.dgraph ();
	} else {
	    auto slave = new Slave (proto, this._lambda);
	    if (info.id < nbWorker) slave.run ();
	    else slave.waitGraph ();
	    return slave.dgraph ();
	}
    }
    
    mixin Singleton!DistGraphLoaderS;
}

alias DistGraphLoader = DistGraphLoaderS.instance;
