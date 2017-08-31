module distGraph.dgraph.Vertex;
import distGraph.dgraph.Edge, distGraph.dgraph.Graph;
import std.container;
import std.outbuffer;
import std.traits;
import distGraph.utils.Colors;

/++
 Structure de données utilisé lors du découpage.
 Elle stocke l'id, et les partition ou le sommet est présent.
+/
struct Vertex {
    /++ L'identifiant du sommet +/
    ulong id;

    /++ Le degré temporaire du sommet (calculé lors de la répartition, est faux par la suite) +/
    ulong degree;

    /++ Liste des partitions ou le sommet est présent +/
    long [] partitions;

    /++
     Params:
     id = un identifiant de partition.
     Returns: Le sommet est il dans la partition id
     +/
    bool isInPartition (ulong id) {
	import std.algorithm;
	return find!("a == cast(long)b") (partitions [], id).length > 0;
    }

    /++
     Ajoute un découpage au sommet
     Params:
     id = un identifiant de partition
     Returns: Le sommet n'était pas dans déjà dans la partition, sinon faux.
     +/
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

    /++
     Returns: le sommet est dans plusieurs partitions
     +/
    bool isCut () {
	return this.partitions.length > 1 && this.partitions [1] != -1;
    }    

    /++
     Returns: le sommets sérialisé dans un tableau.
     +/
    long [] serialize () {
	return (cast (long[]) ([this.id, this.degree, partitions.length])) ~ partitions;
    }

    /++
     Params:
     val = le pointeur vers les données (mis à jour)
     len = la taille des données (mis à jour)
     Returns: Un sommet désériliser
     +/
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

/++
 Classe ancêtre de tous les sommets d'un graphe distribué
+/
class VertexD {

    /++ Les données élémentaire du sommet +/
    private Vertex _data;

    /++
     Params:
     v = les données élémentaire du sommet.
     +/
    this (Vertex v) {
	this._data = v;
    }

    /++
     Returns: Les données élémentaires du sommet.
     +/
    Vertex data () {
	return this._data;
    }

    /++
     Returns: l'identifiant du sommet.
     +/
    ulong id () {
	return this._data.id;
    }

    /++
     Returns: le sommet est dans plusieurs partitions
     +/
    bool isCut () {
	return this._data.isCut;
    }

    /++
     Returns: la liste des partitions ou le sommets est présent.
     +/
    long [] partitions () {
	return this._data.partitions;
    }

    /++
     Returns: le sommet au format .dot
     +/
    override string toString () {
	import std.format;
	return format ("\t\t%d[label=\"%d\"];", this.id, this.id);
    }
    
}

