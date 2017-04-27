module dgraph.Edge;
import std.outbuffer;
import utils.Colors;
import std.traits;
import dgraph.Vertex;

/++
 Structure simpliste d'une arête, utilisé lors du découpage
+/
struct Edge {
    ulong src, dst, color;
}

/++
 Ancetre de toutes les arêtes d'un DistGraph. 
+/
class EdgeD {

    /++ L'identifiant du sommet source +/
    private ulong _src;

    /++ L'identifiant du sommet déstination +/
    private ulong _dst;

    /++ L'identifiant de la partition dans laquelle se trouve l'arête +/
    private ulong _color;
    
    this (Edge e) {
	this._src = e.src;
	this._dst = e.dst;
	this._color = e.color;
    }

    /++ 
     Returns: L'identifiant de la partition dans laquelle se trouve l'arête
     +/
    ulong color () {
	return this._color;
    }

    /++
     Returns: L'identifiant du sommet source
     +/
    ulong src () {
	return this._src;
    }

    /++
     Returns: L'identifiant du sommet déstination
     +/
    ulong dst () {
	return this._dst;
    }        
        
}
