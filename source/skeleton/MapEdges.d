module skeleton.MapEdges;
import mpiez.admin;
public import skeleton.Register;
import std.traits;
import std.algorithm;
import std.conv;
import utils.Options;
import dgraph.Edge;
import dgraph.DistGraph;
import skeleton.Compose;

private bool checkFunc (alias fun) () {
    isSkeletable!fun;
    
    alias a1 = ParameterTypeTuple! (fun);
    alias r1 = ReturnType!fun;
    static assert (a1.length == 1 && is (a1[0] : EdgeD) && is (r1 : EdgeD), "On a besoin de : T2 function (T : VertexD, T2 : VertexD) (T)");
    return true;
}

template MapEdges (alias fun)
    if (checkFunc!fun) {
    
    alias I = ParameterTypeTuple!(fun) [0];
    alias T2 = ReturnType!fun;

    T2 [] map (I [] array) {
	T2 [] res = new T2 [array.length];
	foreach (key, value ; array)
	    res [key] = fun (value);
	return res;
    }
   
    DistGraph!(V, T2) MapEdges (T : DistGraph!(V, I), V) (T a) {
	auto aux = new DistGraph!(V, T2) (a.color, a.nbColor);
	aux.total = a.total;
	aux.edges = map (a.edges);
	aux.vertices = a.vertices;
	return aux;	
    }    
}

alias ReverseEdgeDirection = MapEdges! ((EdgeD ed) => new EdgeD (Edge (ed.dst, ed.src, ed.color)));

