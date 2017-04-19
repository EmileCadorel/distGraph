module skeleton.FilterEdges;
import mpiez.admin;
public import skeleton.Register;
import std.traits;
import std.algorithm;
import std.conv;
import utils.Options;
import dgraph.Edge;
import dgraph.DistGraph;

private bool checkFunc (alias fun) () {
    static assert ((is (typeof(&fun) U : U*) && (is (U == function)) ||
		    is (typeof (&fun) U == delegate)) ||
		   (is (fun T2) && is(T2 == function)) || isFunctionPointer!fun);
    
    alias a1 = ParameterTypeTuple! (fun);
    alias r1 = ReturnType!fun;
    static assert (a1.length == 1 && is (a1[0] : EdgeD) && is (r1 : bool), "On a besoin de : bool function (T : VertexD, T2 : VertexD) (T)");
    return true;
}

template FilterEdges (alias fun)
    if (checkFunc!fun) {
    
    alias E = ParameterTypeTuple!(fun) [0];

    E [] filter (E [] _array) {
	import std.container, std.array;
	Array!E res;
	foreach (value ; _array) {
	    if (fun (value))
		res.insertBack (value);
	}
	return res.array ();
    }
   
    DistGraph!(V, E) FilterEdges (T : DistGraph!(V, E), V) (T a) {
	auto aux = new DistGraph!(V, E) (a.color, a.nbColor);
	aux.total = a.total;
	aux.edges = filter (a.edges);
	aux.vertices = a.vertices;
	return aux;	
    }    
}
