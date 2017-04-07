module dgraph.Vertex;
import dgraph.Edge, dgraph.Graph;
import std.container;
import std.outbuffer;
import std.traits;
import utils.Colors, dgraph.Partition;

/++
 La classe vertex représente un sommet du graphe, il est identifié par un ID unique
+/
class Vertex {
    
    /++ Cet ID doit être unique dans un graphe +/
    private ulong _id;

    private Array!Edge _edges;

    /++ Peut être différent de len (edges) en cours de chargement du graphe +/
    /++ On lis forcement une arête pour découvrir le sommet +/
    private ulong _degree = 1;
    
    private Array!ulong _partitions;
    
    this (ulong id) {
	this._id = id;
    }
    
    const(ulong) id () const {
	return this._id;
    }       

    /++
     Ajoute une arête au sommet.
     +/
    void addEdge (Edge edge) {
	this._edges.insertBack (edge);
    }

    const (Array!ulong) partitions () const {
	return this._partitions;
    }
    
    /++
     Retourne les partitions qui contiennent le sommet.
     +/
    ref Array!ulong partitions () {
	return this._partitions;
    }
    
    bool isInPartition (const ulong p) const {
	import std.algorithm;
	return !(find!"a == b" (this._partitions [], p).empty);
    }

    bool addPartition (const ulong p) {
	import std.algorithm;
	if (find!"a == b" (this._partitions [], p).empty) {
	    this._partitions.insertBack (p);
	    return true;
	}
	return false;
    }

    ref ulong degree () {
	return this._degree;
    }
    
    /++
     Ecris le sommet au format Dot dans le buffer
     +/
    OutBuffer toDot (OutBuffer buf, ulong byPart = 0) {
	if (byPart == 0) {
	    foreach (it; this._edges)
		it.toDot (buf);
	} else {
	    foreach (it ; this._edges) {
		if (it.color == byPart)
		    it.toDot (buf);
	    }
	}
	return buf;
    }

}
