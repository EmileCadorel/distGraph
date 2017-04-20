module skeleton.JoinVertices;
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
    static assert (a1.length == 2 && is (a1[0] : VertexD) && is (r1 == a1 [0]), "On a besoin de : T function (T : VertexD, Msg) (T, Msg)");
    return true;
}

template JoinVertices (alias fun)
    if (checkFunc!fun) {
    
    alias I = ParameterTypeTuple!(fun) [0];
    alias Msg = ParameterTypeTuple!(fun) [1];
    
    I [ulong] map (I [ulong] array, Msg [ulong] values) {
	I [ulong] res;
	foreach (key, value ; array) {
	    if (key in values)
		res [key] = fun (array [key], values [key]);
	    else res [key] = array [key];
	}
	return res;
    }
   
    DistGraph!(I, E) JoinVertices (T : DistGraph!(I, E), E) (T a, Msg [ulong] values) {
	//TODO, synchroniser avec les autres partitions pour voir si tout le monde à le même ID.
	auto aux = new DistGraph!(I, E) (a.color, a.nbColor);
	aux.total = a.total;
	aux.vertices = map (a.vertices, values);
	aux.edges = a.edges;
	return aux;	
    }    
}

