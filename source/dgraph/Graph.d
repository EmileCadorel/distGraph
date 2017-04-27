module dgraph.Graph;
public import dgraph.Vertex;
public import dgraph.Edge;
import std.math, std.algorithm;
import std.stdio;
import std.container;
import std.string, std.conv;
import std.parallelism;
import std.outbuffer;
import std.traits;
import utils.Colors;

/++
 Représentation d'un graphe, non répartie.
 Utilisé lors du découpage, elle ne doit pas être conservé ensuite
 +/
class Graph {

    /++ La taille de l'ensemble des partitions du graphe +/
    private ulong [] _partitions;

    /++ La liste des sommets du graphe +/
    private Vertex [] _vertices;

    /++ La liste des sommets rangé par partitions +/
    private Array!Vertex [] _verticesPart;
    
    /++ La liste des arêtes rangé par partitions +/ 
    private Array!Edge [] _edgesPart;

    /++
     Params:
     nbPart = le nombre de partitions qui vont être créé
     +/
    this (ulong nbPart) {
	if (nbPart > 0) {
	    this._partitions = new ulong [nbPart];
	    this._verticesPart = new Array!Vertex [nbPart];
	    this._edgesPart = new Array!Edge [nbPart];
	}
    }

    /++
     Returns: La tailles des partitions (rangé par id).
     +/
    ref ulong [] partitions () {
	return this._partitions;
    }

    /++
     Returns: la liste des sommets rangé par partitions 
     +/
    Array!Vertex [] vertices () {
	return this._verticesPart;
    }

    /++
     Returns: la liste des arêtes rangé par partitions 
     +/
    Array!Edge [] edges () {
	return this._edgesPart;
    }

    /++
     Returns: La liste des sommets, désordonnées
     +/
    Vertex [] verticesTotal () {
	return this._vertices;
    }
    
    /++
     Params:
     id = un identifiant de sommet
     Returns: le sommet identifié par id, (le créer si il n'existe pas)
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
     Params:
     e = l'arête à ajouter
     +/
    void addEdge (Edge e) {
	//this._edges.insertBack (e);
	this._edgesPart [e.color].insertBack (e);
	this._vertices [e.src].degree ++;
	this._vertices [e.dst].degree ++;
	if (this._vertices [e.src].addPartition (e.color)) {
	    this._partitions [e.color] ++;
	    this._verticesPart [e.color].insertBack(this._vertices [e.src]);
	}
	
	if (this._vertices [e.dst].addPartition (e.color)) {
	    this._partitions [e.color] ++;
	    this._verticesPart [e.color].insertBack(this._vertices [e.dst]);
	}
    }
}
    

