module dgraph.Graph;
public import dgraph.Vertex;
public import dgraph.Edge, dgraph.Partition;
import std.math, std.algorithm;
import std.stdio;
import std.container;
import std.string, std.conv;
import std.parallelism;
import std.outbuffer;

/++
 Représentation d'un graphe
 Params:
 VD = le type de données des vertex
 ED = le type de données des arêtes
+/
class Graph {

    private Vertex [] _vertices;
    private Array!Edge _edges;
    private ulong _max = 0UL;
    private Array!Partition _partitions;
    
    const (Vertex []) vertices () {
	return this._vertices;	
    }
    
    const (Array!(Edge)) edges () {
	return this._edges;
    }

    Vertex getVertex (ulong id) {
	if (this._vertices.length <= id) {
	    auto aux = new Vertex [id - this._vertices.length + 1];
	    foreach (it ; 0 .. aux.length)
		aux [it] = new Vertex (it + this._vertices.length);
	    this._vertices ~= aux;
	}
	return this._vertices [id];
    }

    ref Array!Partition partitions () {
	return this._partitions;
    }	

    void addEdge (Array!Edge edges) {
	foreach (e ; edges) {
	    this._vertices [e.src].addEdge (e);
	    this._edges.insertBack (e);
	}
    }

    void addEdge (Edge e) {
	this._vertices [e.src].addEdge (e);
	this._edges.insertBack (e);
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
		if (vt && vt.partitions.length > 1) {			
		    buf.writefln ("\t\t%d[label=\"%d/%d\"];", vt.id, vt.id, vt.degree);
		} else if (vt.partitions.length == 1) {
		    parts [vt.partitions [0] - 1] ~= [vt.id];
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
	
	foreach (vt ; this._vertices)
	    vt.toDot (buf);	
		
	buf.writefln ("}");
	return buf;
    }
        
           
}
    

