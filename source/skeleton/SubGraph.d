module skeleton.SubGraph;
import mpiez.admin;
public import skeleton.Register;
import std.traits;
import std.algorithm, std.container;
import std.conv, std.array;
import utils.Options;
import dgraph.Vertex, dgraph.Edge, dgraph.DistGraph;
import skeleton.Compose;

private bool checkFuncVert (alias fun) () {
    isSkeletable!fun;
    alias a1 = ParameterTypeTuple! (fun);
    alias r1 = ReturnType!fun;
    static assert (is (a1[0] : VertexD) && is (r1 == bool), "On a besoin de : bool function (Vertex)");        

    return true;
}

private bool checkFuncEdge (alias fun) () {
    isSkeletable!fun;
    alias a1 = ParameterTypeTuple! (fun);
    alias r1 = ReturnType!fun;
    static assert (is (a1[0] : EdgeD) && is (r1 == bool), "On a besoin de : bool function (Edge)");        

    return true;
}

template SubGraph (X ...)
    if (X.length == 2 && checkFuncEdge!(X [1]) && checkFuncVert!(X [0])) {

     DistGraph!(VD, ED) SubGraph (T : DistGraph!(VD, ED), VD, ED) (T grp) {
	 auto aux = new DistGraph!(VD, ED) (grp.color, grp.nbColor);
	 aux.total = grp.total;
	 foreach (key, vt ; grp.vertices) {
	     if (X [0] (vt))
		 aux.addVertex (vt);
	 }
	 
	 Array!EdgeD edges;
	 foreach (et ; grp.edges) {
	     if (aux.hasVertex (et.src) && aux.hasVertex (et.dst))
		 if (X [1] (et)) edges.insertBack (et);
	 }
	 
	 aux.edges = edges.array ();	
	 return aux;
    }
    
    
}




