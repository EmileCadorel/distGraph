module dgraph.Graph;
public import dgraph.Vertex;
public import dgraph.Edge, dgraph.Partition;
import std.math, std.algorithm;
import std.stdio;
import std.container;
import std.string, std.conv;
import std.parallelism;
import std.outbuffer;
import std.traits;
import utils.Colors;

/++
 Représentation d'un graphe
 Params:
 VD = le type de données des vertex
 ED = le type de données des arêtes
 +/
class Graph {

    /++ La taille de l'ensemble des partitions du graphe +/
    private ulong [] _partitions;

    /++ La liste des sommets du graphe +/
    private Vertex [] _vertices;

    /++ La liste des arêtes du graphes +/
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

    /++
     Ajoute une arête au graphe, met à jour les sommets associé, ainsi que la table des partitions.     
     +/
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
    

