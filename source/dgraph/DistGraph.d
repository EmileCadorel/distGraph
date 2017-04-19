module dgraph.DistGraph;
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
import dgraph.Graph;


class DistGraph {

    private Vertex [ulong] _vertices;

    private Edge[] _edges;

    private ulong _color;
    
    this (ulong color) {
	this._color = color;
    }

    Vertex [ulong] vertices () {
	return this._vertices;
    }    
    
    ref Edge [] edges () {
	return this._edges;
    }

    bool hasVertex (ulong id) {
	return (id in this._vertices) !is null;
    }
    
    Vertex getVertex (ulong id) {
	auto vt = id in this._vertices;
	if (vt is null) assert (false);
	return *vt;
    }

    void addVertex (Vertex vt) {
	this._vertices [vt.id] = vt;
    }
    
    ulong color () {
	return this._color;
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
	    foreach (key, vt; this._vertices) {
		if (vt.partitions.length > 1 && vt.partitions [1] != -1)
		    buf.writefln ("\t\t%d[label=\"%d/%d\"];", vt.id, vt.id, vt.partitions [1]);
	    }
	    buf.writefln ("\n\t}");
	}
    
	foreach (vt ; this._edges) {
	    buf.writefln ("\t%d -> %d [color=\"/%s\"]", vt.src, vt.dst,
			  vt.color < 9 ? [EnumMembers!Color][vt.color].value : "");	    
	}
		
	buf.writefln ("}");
	return buf;
    }

}

