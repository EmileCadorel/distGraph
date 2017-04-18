import mpiez.Process;
import std.container;
import std.outbuffer;
import utils.Colors, std.traits;

enum WINDOW_SIZE = 1;
enum MAX_CUT = 10;

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

    // l'etat courant du graphe
    Message!(4, ubyte*, ulong, ulong []) getState;

    // Met a jour le graphe
    Message!(5, Edge[]) putState;

    Message!(6, byte) end;
}

struct Edge {
    ulong src, dst, color;
}

struct Vertex {
    ulong id;

    ulong degree;
    
    // On va partir du principe que pour le moment
    // il peut pas etre dans MAX_CUT partitions à la fois
    long [] partitions;

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


    long [] serialize () {
	return (cast (long[]) ([this.id, this.degree, partitions.length])) ~ partitions;
    }
    
    static Vertex deserialize (ref ubyte * val, ref ulong len) {
	Vertex v;
	auto value = cast (ulong*) val;
	v.id = *(value);
	v.degree = *(value + 1);
	auto parts = cast (long*) (value + 2);
	auto nb = *parts;
	v.partitions = new long [nb];
	foreach (it ; 0 .. nb) {
	    v.partitions [it] = *(parts + it + 1);
	}
	
	auto aux = cast (ubyte*) (parts + nb + 1);
	len -= aux - val;
	val = aux;
	return v;
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


    /++
     Retourne le vertex (id), (le créer si il n'existe pas)
     +/
    ref Vertex getVertex (ulong id) {
	if (this._vertices.length <= id) {	    
	    auto aux = new Vertex [id - this._vertices.length + 1];
	    foreach (it ; 0 .. aux.length) {
		aux [it] = Vertex (it + this._vertices.length, 0, new long [this._partitions.length]);
		foreach (ref pt; aux [it].partitions)
		    pt = -1;
	    }
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
