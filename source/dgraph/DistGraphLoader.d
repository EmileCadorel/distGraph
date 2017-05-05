module dgraph.DistGraphLoader;
import utils.Singleton;
import std.stdio;
import dgraph.Graph;
public import dgraph.Edge, dgraph.Vertex;
import std.string, std.conv;
import std.container, std.algorithm;
import mpiez.Message, mpiez.Process;
import dgraph.Master, dgraph.Slave;
import skeleton.Register;
import mpiez.admin;
import utils.Options;
public import dgraph.DistGraph;

/++
 Nombre d'arête lu par un partitionner avant de les placer dans des partitions
+/
enum WINDOW_SIZE = 1;

/++
 Tag des requêtes envoyées au lecteur de fichier
+/
enum EDGE = 0;
enum STATE = 1;
enum PUT = 2; 
enum END = 3;

/++
 Union permettant de transformer facilement une structure en ubyte*
 Params:
 T = un type struct*
 U = un type struct (déduis automatiquement)
+/
union Serializer (T : U*, U) {
    T value;
    ubyte * ptr;
}

/++
 Protocol utilisé entre le lecteurs de fichier et les partitionneurs 
 +/
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

    /++ Id de la requete +/
    Message!(1, byte) request;

    /++ Donnees, taille des donnees +/
    Message!(2, ubyte*, ulong) edge;

    /++ Les identifiants des vertices +/
    Message!(3, ulong []) state;

    /++ l'etat courant du graphe, (Vertex, partitions) +/
    Message!(4, ubyte*, ulong, ulong []) getState;

    /++ Met a jour le graphe +/
    Message!(5, Edge[]) putState;

    /++ Envoie des arêtes à une partitions +/
    Message!(7, Edge []) graphEdge;

    /++ Envoie des sommets à une partition (Vertex[] sérialisé) +/
    Message!(8, long []) graphVert;
    
    Message!(6, ulong) end;
}


/++ 
 Classe singleton qui se charge de lire et découper un graphe entre les noeuds MPI déjà lancé
 +/
class DistGraphLoaderS {

    /++
     Un des paramètres de l'heuristique 
     Plus lambda est grand, plus le découpage va séparer les sommets
     +/
    private float _lambda = 1.8;

    /++
     Plus lambda est grand, plus le découpage va séparer les sommets
     Returns: un paramètre de l'heuristique
     +/
    ref float lambda () {
	return this._lambda;
    }

    /++
     Lis un fichier, le découpe en partitions répartie sur les différents noeuds de calcul
     Params:
     filename = le nom du fichier au format edge.
     nbWorker = le nombre de noeud qui vont travailler au découpage (les autres se mettent en attente d'informations d'arête et de sommets)
     linear = la répartition va se faire dans l'ordre d'apparition ?
     Returns: Une partitions du graphe correspondant au noeud de calcul courant
     +/
    DistGraph!(VertexD, EdgeD) open (string filename, int nbWorker = 2, bool linear = true) {
	auto info = Proto.commInfo (MPI_COMM_WORLD);
	nbWorker = info.total < nbWorker ? info.total : nbWorker;
	auto proto = new Proto (info.id, info.total);
	if (!linear) {
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
	} else {
	    if (info.id == 0) {
		auto master = new Master (proto, filename, info.total);
		master.runLinear ();	    
		return master.dgraph ();
	    } else {
		auto slave = new Slave (proto, this._lambda);
		slave.waitGraph ();
		return slave.dgraph ();
	    }
	}
    }
    
    /++ C'est classe est un singleton +/
    mixin Singleton!DistGraphLoaderS;
}

/++ Alias pour éviter d'avoir à écrire .instance à chaque fois +/
alias DistGraphLoader = DistGraphLoaderS.instance;
