module dgraph.Edge;
import std.outbuffer;
import utils.Colors;
import std.traits;
import dgraph.Vertex;

struct Edge {
    ulong src, dst, color;
}

class EdgeD {

    private ulong _src;
    private ulong _dst;
    private ulong _color;
    
    this (Edge e) {
	this._src = e.src;
	this._dst = e.dst;
	this._color = e.color;
    }

    ulong color () {
	return this._color;
    }

    ulong src () {
	return this._src;
    }

    ulong dst () {
	return this._dst;
    }        
        
}
