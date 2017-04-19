module dgraph.DistGraph;
public import dgraph.Vertex;
public import dgraph.Edge, dgraph.Partition;
import std.math, std.algorithm;
import std.stdio;
import std.container;
import std.string, std.conv;
import std.parallelism;
import std.outbuffer;
import std.traits, std.container;
import utils.Colors;
import dgraph.Graph;


class DistGraph (VD, ED) {

    private VD [ulong] _vertices;

    private Array!(VD) [] _cuts;

    private ulong _total;
    
    private ED [] _edges;

    private ulong _color;
    
    this (ulong color, ulong total) {
	this._color = color;
	this._cuts = new Array!VD [total];
    }

    ref VD [ulong] vertices () {
	return this._vertices;
    }    

    Array!VD [] cuts () {
	return this._cuts;
    }

    const (ulong) nbColor () {
	return this._cuts.length;
    }
    
    ref ulong total () {
	return this._total;
    }
    
    ulong communicate (ulong color) {
	return this._cuts [color].length;
    }    
    
    ref ED [] edges () {
	return this._edges;
    }

    void setEdges (Edge [] edges) {
	this._edges = new ED [edges.length];
	foreach (i, it ; edges) {
	    this._edges [i] = new ED (it);
	}
    }
    
    bool hasVertex (ulong id) {
	return (id in this._vertices) !is null;
    }
    
    VD getVertex (ulong id) {
	auto vt = id in this._vertices;
	if (vt is null) assert (false);
	return *vt;
    }

    void addVertex (Vertex vt) {
	this._vertices [vt.id] = new VD (vt);
	if (vt.isCut) {	    
	    foreach (it ; vt.partitions) {
		if (it == -1) break;
		else if (it != this._color)
		    this._cuts [it].insertBack (this._vertices [vt.id]);
	    }
	}
    }    

    void addVertex (VD vt) {
	this._vertices [vt.id] = vt;
	if (vt.isCut) {
	    foreach (it ; vt.partitions) {
		if (it == -1) break;
		else if (it != this._color)
		    this._cuts [it].insertBack (vt);
	    }
	}
    }
    
    ulong color () {
	return this._color;
    }
    
    /++
     Ecris le graphe au format Dot dans un buffer
     +/
    OutBuffer toDot (OutBuffer buf = null, bool byPart = false) {
	if (buf is null) buf = new OutBuffer;

	auto bufCut = new OutBuffer;
	buf.writefln ("digraph G {");	
	bufCut.writefln ("\tsubgraph cluster_cut {");
	bufCut.writefln ("\t\tnode [style=filled];\n\t\tlabel=\"Part Cut\";\n\t\tpenwidth=10; \n\t\tcolor=blue;");

	buf.writefln ("\tsubgraph cluster_0 {");
	buf.writefln ("\t\tnode [style=filled];");
	
	
	foreach (key, vt; this._vertices) {
	    if (vt.partitions.length > 1 && vt.partitions [1] != -1)
		bufCut.writefln (vt.toString);
	    else buf.writefln ("%s", vt.toString);
	}
	
	bufCut.writefln ("\n\t}");
	buf.writefln ("}\n%s", bufCut.toString);
    
	foreach (vt ; this._edges) {
	    buf.writefln ("\t%d -> %d", vt.src, vt.dst);	    
	}
		
	buf.writefln ("}");
	return buf;
    }

}

