import mpiez.Process;
import std.container;
import std.outbuffer;
import utils.Colors, std.traits;

enum WINDOW_SIZE = 1;
enum MAX_CUT = 10;

class Proto : Protocol {
    this (int id, int total) {
	super (id, total);
	this.request = new Message!(1, int);
	this.edge = new Message!(2, ubyte*, ulong);
	this.state = new Message!(3, ulong []);
	this.getState = new Message!(4, Vertex[], ulong[]);
	this.putState = new Message!(5, Edge []);
    }

    // Id de la requete
    Message!(1, int) request;

    // Donnees, taille des donnees
    Message!(2, ubyte*, ulong) edge;

    // Les identifiants des vertices
    Message!(3, ulong []) state;

    // l'etat courant du graphe
    Message!(4, Vertex[], ulong []) getState;

    // Met a jour le graphe
    Message!(5, Edge[]) putState;
}

struct Edge {
    ulong src, dst, color;
}

struct Vertex {
    ulong id;

    ulong degree;
    
    // On va partir du principe que pour le moment
    // il peut pas etre dans MAX_CUT partitions à la fois
    long [MAX_CUT] partitions;

    bool isInPartition (ulong id) {
	import std.algorithm;
	return find!("a == cast(long)b") (partitions [], id).length > 0;
    }

    bool addPartition (ulong id) {
	foreach (ref it ; this.partitions) {
	    if (it == id) return false;
	    else if (it == -1) {
		it = id;
		return true;
	    }
	}
	assert (false, "Trop de découpage");
    }
    
}


class Graph {

    private ulong [] _partitions;

    private Vertex [] _vertices;

    private Array!Edge _edges;
    
    this (ulong nbPart) {
	this._partitions = new ulong [nbPart];	
    }

    ref ulong [] partitions () {
	return this._partitions;
    }

    ref Vertex getVertex (ulong id) {
	if (this._vertices.length <= id) {
	    import std.algorithm;
	    long [MAX_CUT] empty;
	    foreach (it ; 0 .. empty.length)
		empty [it] = -1L;
	    
	    auto aux = new Vertex [id - this._vertices.length + 1];
	    foreach (it ; 0 .. aux.length) 
		aux [it] = Vertex (it + this._vertices.length, 0, empty);
	    this._vertices ~= aux;
	}
	return this._vertices [id];
    }

    void addEdge (Array!Edge edges) {
	this._edges ~= edges;
    }

    void addEdge (Edge e) {
	this._edges.insertBack (e);
	this._vertices [e.src].degree ++;
	this._vertices [e.dst].degree ++;
	if (this._vertices [e.src].addPartition (e.color))
	    this._partitions [e.color] ++;
	if (this._vertices [e.dst].addPartition (e.color))
	    this._partitions [e.color] ++;
    }

        /++
     Ecris le graphe au format Dot dans un buffer
     +/
    OutBuffer toDot (OutBuffer buf = null, bool byPart = false) {
	if (buf is null)
	    buf = new OutBuffer;
	buf.writefln ("digraph G {");
	
	if (byPart) {	    
	    buf.writefln ("\tsubgraph cluster_cut {");
	    buf.writefln ("\t\tnode [style=filled];\n\t\tlabel=\"Part Cut\";\n\t\tpenwidth=10; \n\t\tcolor=blue;");
	    ulong [][] parts = new ulong [][this._partitions.length];	    
	    foreach (vt ; this._vertices) {
		if (vt.partitions [1] != -1) {			
		    buf.writefln ("\t\t%d[label=\"%d/%d\"];", vt.id, vt.id, vt.degree);
		} else if (vt.partitions [0] != -1) {
		    parts [vt.partitions [0]] ~= [vt.id];
		}
	    }	    
	    buf.writefln ("\n\t}");

	    foreach (pt ; 0 .. parts.length) {
		buf.writefln ("\tsubgraph cluster_%d {", pt);
		buf.writefln ("\t\tnode [style=filled; line=10];\n\t\tlabel=\"Part %d\";\n\t\tpenwidth=10;", pt);
		foreach (vt ; parts [pt]) {
		    buf.writefln ("\t\t%d;", vt);
		}
		
		buf.writefln ("\n\t}");
	    }	    
	}
	
	foreach (vt ; this._edges) {
	    buf.writefln ("\t%d -> %d [color=\"/%s\"]", vt.src, vt.dst,
			  vt.color < 9 ? [EnumMembers!Color][vt.color].value : "");	    
	}
		
	buf.writefln ("}");
	return buf;
    }


}

union Serializer (T : U*, U) {
    T value;
    ubyte * ptr;
}

enum EDGE = 0;
enum STATE = 1;
enum PUT = 2; 
enum END = 3;
