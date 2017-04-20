module skeleton.MapVertices;
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
		   (is (fun T2) && is(T2 == function)) ||
		   isFunctionPointer!fun ||
		   isDelegate!fun
    );
    
    alias a1 = ParameterTypeTuple! (fun);
    alias r1 = ReturnType!fun;
    static assert (a1.length == 1 && is (a1[0] : VertexD) && is (r1 : VertexD), "On a besoin de : T2 function (T : VertexD, T2 : VertexD) (T)");
    return true;
}

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
   
    DistGraph!(T2, E) MapVertices (T : DistGraph!(I, E), E) (T a) {
	//TODO, synchroniser avec les autres partitions pour voir si tout le monde à le même ID.
	auto aux = new DistGraph!(T2, E) (a.color, a.nbColor);
	aux.total = a.total;
	aux.vertices = map (a.vertices);
	aux.edges = a.edges;
	return aux;	
    }    
}

