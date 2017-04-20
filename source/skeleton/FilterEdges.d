module skeleton.FilterEdges;
import mpiez.admin;
public import skeleton.Register;
import std.traits;
import std.algorithm;
import std.conv, std.typecons;
import utils.Options;
import dgraph.Edge;
import dgraph.DistGraph;
import skeleton.Compose;

private bool checkFunc (alias fun) () {
    isSkeletable!fun;
    
    alias a1 = ParameterTypeTuple! (fun);
    alias r1 = ReturnType!fun;
    static assert (a1.length == 1 && is (a1[0] : EdgeD) && is (r1 : bool), "On a besoin de : bool function (T : VertexD, T2 : VertexD) (T)");
    return true;
}

private bool checkFuncTriplets (alias fun) () {
    isSkeletable!fun;
    
    alias a1 = ParameterTypeTuple! (fun);
    alias r1 = ReturnType!fun;
    static assert (a1.length == 1 && is (a1[0] :  Tuple!(VD, "src", VD, "dst", ED, "edge"), VD, ED) && is (r1 : bool), "On a besoin de : bool function (T : VertexD, T2 : VertexD) (T)");
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

template FilterEdgeTriplets (alias fun)
    if (checkFuncTriplets!fun) {
    
    alias E = typeof(ParameterTypeTuple!(fun) [0].edge);

    E [] filter (T : DistGraph!(VD, ED), VD, ED) (T gp) {
	import std.container, std.array;
	Array!ED res;
	foreach (it ; gp.edges) {
	    auto triplets = EdgeTriplet!(VD, ED) (gp.vertices [it.src], gp.vertices [it.dst], it);
		    
	    if (fun (triplets))
		res.insertBack (it);
	}
	return res.array ();
    }
   
    DistGraph!(V, E) FilterEdgeTriplets (T : DistGraph!(V, E), V) (T a) {
	auto aux = new DistGraph!(V, E) (a.color, a.nbColor);
	aux.total = a.total;
	aux.edges = filter (a);
	aux.vertices = a.vertices;
	return aux;	
    }    

}
