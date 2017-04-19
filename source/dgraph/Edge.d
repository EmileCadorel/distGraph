module dgraph.Edge;
import std.outbuffer;
import utils.Colors;
import std.traits;


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

    final EdgeD reverse () {
	auto res = this.clone ();
	res._dst = res._src;
	res._src = this._dst;
	return res;
    }

    EdgeD clone () {
	return new EdgeD (Edge (this._src, this._dst, this._color));
    }
    
}
