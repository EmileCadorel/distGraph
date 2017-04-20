module skeleton.JoinVertices;
import mpiez.admin;
public import skeleton.Register;
import std.traits;
import std.algorithm;
import std.conv;
import utils.Options;
import dgraph.Vertex;
import dgraph.DistGraph;
import skeleton.Compose;

private bool checkFunc (alias fun) () {
    isSkeletable!fun;
    
    alias a1 = ParameterTypeTuple! (fun);
    alias r1 = ReturnType!fun;
    static assert (a1.length == 2 && is (a1[0] : VertexD) && is (r1 : VertexD), "On a besoin de : T function (T : VertexD, Msg) (T, Msg)");
    return true;
}

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
   
    DistGraph!(T2, E) JoinVertices (T : DistGraph!(I, E), E) (T a, Msg [ulong] values) {
	//TODO, synchroniser avec les autres partitions pour voir si tout le monde à le même ID.
	auto aux = new DistGraph!(T2, E) (a.color, a.nbColor);
	aux.total = a.total;
	aux.vertices = map (a.vertices, values);
	aux.edges = a.edges;
	return aux;	
    }    
}

