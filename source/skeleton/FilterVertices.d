module skeleton.FilterVertices;
import mpiez.admin;
public import skeleton.Register;
import std.traits;
import std.algorithm;
import std.conv;
import utils.Options;
import dgraph.Vertex;
import dgraph.DistGraph;

private bool checkFunc (alias fun) () {
    static assert ((is (typeof(&fun) U : U*) && (is (U == function)) ||
		    is (typeof (&fun) U == delegate)) ||
		   (is (fun T2) && is(T2 == function)) || isFunctionPointer!fun);
    
    alias a1 = ParameterTypeTuple! (fun);
    alias r1 = ReturnType!fun;
    static assert (a1.length == 1 && is (a1[0] : VertexD) && is (r1 : bool), "On a besoin de : T2 function (T : VertexD, T2 : VertexD) (T)");
    return true;
}

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
   
    DistGraph!(I, E) FilterVertices (T : DistGraph!(I, E), E) (T a) {
	//TODO, synchroniser avec les autres partitions pour voir si tout le monde à le même ID.
	auto aux = new DistGraph!(I, E) (a.color, a.nbColor);
	aux.total = a.total;
	aux.vertices = filter (a.vertices);
	aux.edges = a.edges;
	return aux;	
    }    
}

