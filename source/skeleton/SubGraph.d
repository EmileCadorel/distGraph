module skeleton.SubGraph;
import mpiez.admin;
public import skeleton.Register;
import std.traits;
import std.algorithm;
import std.conv;
import utils.Options;
import dgraph.Vertex, dgraph.Edge, dgraph.DistGraph;

private bool checkFuncVert (alias fun) () {
    static assert ((is (typeof(&fun) U : U*) && (is (U == function)) ||
		    is (typeof (&fun) U == delegate)) ||
		   (is (fun T2) && is(T2 == function)) || isFunctionPointer!fun);
    
    alias a1 = ParameterTypeTuple! (fun);
    alias r1 = ReturnType!fun;
    static assert (is (a1[0] : Vertex) && is (r1 == bool), "On a besoin de : bool function (Vertex)");        

    return true;
}

private bool checkFuncEdge (alias fun) () {
    static assert ((is (typeof(&fun) U : U*) && (is (U == function)) ||
		    is (typeof (&fun) U == delegate)) ||
		   (is (fun T2) && is(T2 == function)) || isFunctionPointer!fun);
    
    alias a1 = ParameterTypeTuple! (fun);
    alias r1 = ReturnType!fun;
    static assert (is (a1[0] : Edge) && is (r1 == bool), "On a besoin de : bool function (Edge)");        

    return true;
}

template SubGraph (X ...)
    if (X.length == 2 && checkFuncEdge!(X [1]) && checkFuncVert!(X [0])) {

    DistGraph run (DistGraph grp) {
	auto aux = new DistGraph (grp.color);
	foreach (key, vt ; grp.vertices) {
	    if (X [0] (vt))
		aux.addVertex (vt);
	}

	foreach (et ; grp.edges) {
	    if (aux.hasVertex (et.src) && aux.hasVertex (et.dst))
		if (X [1] (et)) aux.addEdge (et);
	}
	
	return aux;
    }
    
    
}




