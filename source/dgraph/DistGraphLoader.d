module dgraph.DistGraphLoader;
import utils.Singleton;
import std.stdio;
import dgraph.Graph, dgraph.Edge;
import std.string, std.conv;
import std.container, std.algorithm;
import dgraph.Partition;
import mpiez.Message, mpiez.Process;
import dgraph.Master, dgraph.Slave;

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
	this.end = new Message!(6, byte);
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

    Message!(6, byte) end;
}


class DistGraphLoaderS {

    private float _lambda = 1.8;

    ref float lambda () {
	return this._lambda;
    }
    
    Graph open (string filename, ulong nbPart) {
	auto info = Proto.commInfo (MPI_COMM_WORLD);
	auto proto = new Proto (info.id, info.total);
	if (info.id == 0) {
	    auto master = new Master (proto, filename, nbPart);
	    master.run ();
	    return master.graph ();
	} else {
	    auto slave = new Slave (proto, this._lambda);
	    slave.run ();
	    return null;
	} 
    }
    
    mixin Singleton!DistGraphLoaderS;
}

alias DistGraphLoader = DistGraphLoaderS.instance;
