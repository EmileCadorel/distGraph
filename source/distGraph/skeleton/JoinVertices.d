module distGraph.skeleton.JoinVertices;
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
    static assert (a1.length == 2 && is (a1[0] : VertexD) && is (r1 : VertexD), "On a besoin de : T function (T : VertexD, Msg) (T, Msg)");
    return true;
}

/++
 Fonction de map sur les sommets d'un graphe, avec un tableau associatif des valeurs à ajouter.
 Chaque sommet lance la fonction sur lui et la valeur associé dans le tableau.
 Si aucun valeur n'est associé au sommet dans le tableau 
 - soit La fonction de map retourne le même type que le sommet et le sommet est conservé
 - soit le type est différent et une instance sans valeur associé est crée.

 Params:
 fun = une fonction (T2 function (T : VertexD, Msg, T2) (T, Msg))

 Example:
 -------
 // DistGraph!(VertexD, EdgeD) grp = ...
 
 auto grp2 = grp.JoinVertices!(
     (VertexD vd, ulong deg) => new DegVertex (vd, deg)
 ) (grp.outDegree); 
 -------

 +/
template JoinVertices (alias fun)
    if (checkFunc!fun) {
    
    alias I = ParameterTypeTuple!(fun) [0];
    alias T2 = ReturnType!(fun);
    alias Msg = ParameterTypeTuple!(fun) [1];
    
    T2 [ulong] map (I [ulong] array, Msg [ulong] values) {
	T2 [ulong] res;
	foreach (key, value ; array) {
	    if (key in values)
		res [key] = fun (array [key], values [key]);
	    else {
		static if (is (T2 == I))
		    res [key] = array [key];
		else
		    res [key] = new T2 (array [key].data);
	    }
	}
	return res;
    }
    
    /++
     Cette fonction ne se synchronise pas avec les autres processus
     Elle peut être lancé indépendament.
     Params:
     a = le graph répartie
     values = les valeurs associé au sommet.
     +/
    DistGraph!(T2, E) JoinVertices (T : DistGraph!(I, E), E) (T a, Msg [ulong] values) {
	//TODO, synchroniser avec les autres partitions pour voir si tout le monde à le même ID.
	auto aux = new DistGraph!(T2, E) (a.color, a.nbColor);
	aux.total = a.total;
	aux.vertices = map (a.vertices, values);
	aux.edges = a.edges;
	return aux;	
    }    
}

