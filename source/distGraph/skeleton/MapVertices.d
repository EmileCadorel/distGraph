module distGraph.skeleton.MapVertices;
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
    static assert (a1.length == 1 && is (a1[0] : VertexD) && is (r1 : VertexD), "On a besoin de : T2 function (T : VertexD, T2 : VertexD) (T)");
    return true;
}

/++
 Applique une fonction de map à tout les sommets.
 Params:
 fun = une fonction de map.
 Example:
 -----
 // DistGraph!(VertexD, EdgeD) grp = ...;
 
 auto grp2 = grp.MapVertices!(
     (VertexD vd) => new RankVertex (vd.data, 1.0)
 );

 -----
+/
template MapVertices (alias fun)
    if (checkFunc!fun) {
    
    alias I = ParameterTypeTuple!(fun) [0];
    alias T2 = ReturnType!fun;

    T2 [ulong] map (I [ulong] array) {
	T2 [ulong] res;
	foreach (key, value ; array)
	    res [key] = fun (array [key]);
	return res;
    }

    /++
     Cette fonction peut être lancé indépendament sur chaque processus.
     Aucune communication n'est faite.
     +/
    DistGraph!(T2, E) MapVertices (T : DistGraph!(I, E), E) (T a) {
	//TODO, synchroniser avec les autres partitions pour voir si tout le monde à le même ID.
	auto aux = new DistGraph!(T2, E) (a.color, a.nbColor);
	aux.total = a.total;
	aux.vertices = map (a.vertices);
	aux.edges = a.edges;
	return aux;	
    }    
}

