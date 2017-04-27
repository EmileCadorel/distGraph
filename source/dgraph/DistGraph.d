module dgraph.DistGraph;
public import dgraph.Vertex;
public import dgraph.Edge;
import std.math, std.algorithm;
import std.stdio;
import std.container;
import std.string, std.conv;
import std.parallelism;
import std.outbuffer;
import std.traits, std.container;
import utils.Colors;
import dgraph.Graph;

/++
 Classe possédant une partition du graphe, chaque noeud de calcul en possède un instance
 Params:
 VD = le type de sommet contenu dans le graphe
 ED = le type d'arête contenu dans le graphe
+/
class DistGraph (VD : VertexD, ED : EdgeD) {

    /++ 
     Le tableau associatifs des sommets => Sommet [id] 
     +/
    private VD [ulong] _vertices;

    /++ 
     La liste de partitions, avec les sommets qui sont partagé entre les partitions 
     Example:
     -------
     _color = 2;
     _cuts = [[1, 2], [7, 6]]; // La partitions 2 partage [1,2] avec 0 et [7,6] avec 1
     -------
     +/
    private Array!(VD) [] _cuts;
    
    /++
     Le nombre de sommets total dans le graphe si il n'était pas répartie
     +/
    private ulong _total;

    /++
     La liste d'arêtes de la partitions, elle n'appartiennent qu'a une seule partition
     +/
    private ED [] _edges;

    /++
     L'identifiant de la partition
     +/
    private ulong _color;

    
    this (ulong color, ulong total) {
	this._color = color;
	this._cuts = new Array!VD [total];
    }

    /++
     Returns: la liste des sommets de la partition
     +/
    ref VD [ulong] vertices () {
	return this._vertices;
    }    

    /++
     Returns: la liste des partages de la partition
     +/
    Array!VD [] cuts () {
	return this._cuts;
    }

    /++
     Returns: le nombre de partitions de découpage du graphe total
     +/
    const (ulong) nbColor () {
	return this._cuts.length;
    }

    /++
     Returns: le nombre de sommets du graphe total
     +/
    ref ulong total () {
	return this._total;
    }

    /++
     Params:
     color = la partition en communication avec la partition courante
     Returns: le nombre de sommets en communication avec une autre partition
     +/
    ulong communicate (ulong color) {
	return this._cuts [color].length;
    }    

    /++
     Returns: La liste d'arête contenu dans la partition
     +/
    ref ED [] edges () {
	return this._edges;
    }

    /++
     Met à jour la liste d'arête de la partition
     Params:
     edges = la nouvelle liste d'arête
     +/
    void setEdges (Edge [] edges) {
	this._edges = new ED [edges.length];
	foreach (i, it ; edges) {
	    this._edges [i] = new ED (it);
	}
    }

    /++
     Params:
     id = un identifiant de sommet [0 .. total]
     Returns: le sommet appartient à la partition ?
     +/
    bool hasVertex (ulong id) {
	return (id in this._vertices) !is null;
    }

    /++
     Params:
     id = un identifiant de sommet [0 .. total]
     +/
    VD getVertex (ulong id) {
	auto vt = id in this._vertices;
	if (vt is null) assert (false);
	return *vt;
    }

    /++
     Ajoute un sommet à la partitions, met également à jour les informations de communication (Alloue une instance de VD)
     Params:
     vt = Le sommet à ajouter
     +/
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

    /++
     Ajoute un sommet à la partitions, met également à jour les informations de communication
     Params:
     vt = le sommet à ajouter
     +/
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

    /++
     Returns: l'identifiant de la partitions
     +/
    ulong color () {
	return this._color;
    }
    
    /++
     Ecris le graphe au format Dot dans un buffer
     Params:
     buf = le buffer que l'on veut remplir (en créer un si null)
     Returns: Un buffer contenant la partitions sous format .dot
     +/
    OutBuffer toDot (OutBuffer buf = null) {
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

