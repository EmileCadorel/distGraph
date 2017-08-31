module distGraph.skeleton.FilterVertices;
import distGraph.mpiez.admin;
public import distGraph.skeleton.Register;
import std.traits;
import std.algorithm;
import std.conv;
import distGraph.utils.Options;
import distGraph.dgraph.Vertex;
import distGraph.dgraph.DistGraph;
import distGraph.skeleton.Compose;

private bool checkFunc (alias fun) () {
    isSkeletable!fun;
    
    alias a1 = ParameterTypeTuple! (fun);
    alias r1 = ReturnType!fun;
    static assert (a1.length == 1 && is (a1[0] : VertexD) && is (r1 : bool), "On a besoin de : bool function (T : VertexD) (T)");
    return true;
}

/++
 + Squelette de filtre de sommet.
 + Params:
 + fun = une fonction (bool function (T : VD))
 +
 + Example:
 + ------
 + // DistGraph!(DegVertex, EdgeD) grp = ...;
 + // DegVertex contient le degré du sommet.
 +
 + auto grp2 = grp.FilterVertices! (
 +     (DegVertex vd) => return vd.deg < 3
 + );
 +
 + ------
 +
 +/
template FilterVertices (alias fun)
    if (checkFunc!fun) {
    
    alias I = ParameterTypeTuple!(fun) [0];

    I [ulong] filter (I [ulong] array) {
	I [ulong] res;
	foreach (key, value ; array)
	    if (fun (value))
		res [key] = value;
	return res;
    }

    /++
     Cette fonction ne nécéssite aucune synchronisation
     +/
    DistGraph!(I, E) FilterVertices (T : DistGraph!(I, E), E) (T a) {
	import std.container, std.array;
	//TODO, synchroniser avec les autres partitions pour voir si tout le monde à le même ID.
	auto aux = new DistGraph!(I, E) (a.color, a.nbColor);
	aux.total = a.total;
	aux.vertices = filter (a.vertices);
	Array!E arr;
	foreach (it ; a.edges) {
	    if (it.src in aux.vertices && it.dst in aux.vertices)
		arr.insertBack (it);
	}
	aux.edges = arr.array ();
	return aux;	
    }    
}

