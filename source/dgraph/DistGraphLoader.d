module dgraph.DistGraphLoader;
import utils.Singleton;
import std.stdio;
import dgraph.Graph, dgraph.Edge;
import std.string, std.conv;
import std.container, std.algorithm;
import dgraph.Partition;
import mpiez.Message, mpiez.Process;
import dgraph.Master, dgraph.Slave;
import skeleton.Register;
import mpiez.admin;
import utils.Options;
import dgraph.DistGraph;

enum WINDOW_SIZE = 16;

enum EDGE = 0;
enum STATE = 1;
enum PUT = 2; 
enum END = 3;

union Serializer (T : U*, U) {
    T value;
    ubyte * ptr;
}

class GraphProto : Protocol {
    
    this (int id, int total) {
	super (id, total);
	this.edge = new Message !(1, ubyte*, ulong, Edge[]);
	this.end = new Message!(END, byte);
    }

    Message!(1, ubyte*, ulong, Edge []) edge;
    Message!(END, byte) end;
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

    static this () {
	insertSkeleton ("#DistGraphSlave", &distGraphSlave);
    }
    
    DistGraph open (string filename, int nbWorker = 2) {
	auto info = Proto.commInfo (MPI_COMM_WORLD);
	if (info.id == 0) {
	    auto slaveComm = Proto.spawn!"#DistGraphSlave" (nbWorker, ["--lambda", to!string (this._lambda)]);
	    auto slaveInfo = Proto.commInfo (slaveComm);	
	    auto proto = new Proto (slaveInfo.id, slaveInfo.total);
	    auto gp = new GraphProto (info.id, info.total);
	    auto master = new Master (proto, gp, filename, info.total, slaveComm);
	    master.run (nbWorker);	    
	    barrier (slaveComm);
	    proto.disconnect (slaveComm);
	    foreach (it ; 1 .. info.total) {
		gp.end (it, 1);
	    }
	    return master.dgraph ();
	} else {
	    auto grp = new DistGraph (info.total);
	    auto proto = new GraphProto (info.id, info.total);
	    byte useless;
	    while (true) {
		Edge [] edges;
		ubyte * verts; ulong length;
		auto status = proto.probe ();
		if (status.MPI_TAG == END) {
		    proto.end.receive (status.MPI_SOURCE, useless);
		    break;		
		} else {
		    proto.edge.receive (0, verts, length, edges);
		    while (length > 0)
			grp.addVertex (Vertex.deserialize (verts, length));
		    
		    foreach (it ; edges)
			grp.addEdge (it);
		}
	    }
	    return grp;
	}
    }

    static void distGraphSlave (int id, int total) {
	auto parentComm = Proto.parent ();
	auto info = Proto.commInfo (parentComm);
	writeln ("Slave ", info.id, ", ", info.total);
	auto proto = new Proto (info.id, info.total);
	auto slave = new Slave (proto, to!float (Options ["--lambda"]), parentComm);
	
	slave.run ();
	barrier (parentComm);
	proto.disconnect (parentComm);
    }
    
    mixin Singleton!DistGraphLoaderS;
}

alias DistGraphLoader = DistGraphLoaderS.instance;
