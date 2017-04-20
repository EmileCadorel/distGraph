module skeleton.MapReduceVertices;
import mpiez.admin;
public import skeleton.Register;
import std.traits;
import std.algorithm;
import std.conv;
import utils.Options;
import dgraph.Vertex;
import dgraph.DistGraph;
import skeleton.Compose;

private bool checkFuncMap (alias fun) () {
    isSkeletable!fun;
    
    alias a1 = ParameterTypeTuple! (fun);
    alias r1 = ReturnType!fun;
    static assert (a1.length == 1 && is (a1[0] : VertexD) && !is (r1 : Object), "On a besoin de : T2 function (T : VertexD, T2 !: Object) (T)");
    return true;
}

private bool checkFuncReduce (alias fun, Msg) () {
    isSkeletable!fun;
    
    alias a1 = ParameterTypeTuple! (fun);
    alias r1 = ReturnType!fun;
    static assert (a1.length == 2 && is (a1[0] == Msg) && is (a1 [1] == Msg) && is (r1 == Msg), "On a besoin de : Msg function (Msg !: Object) (Msg, Msg)");
    return true;
}

template MapReduceVertices (Fun ...)
    if (Fun.length == 2) {

    static assert (checkFuncMap!(Fun [0]));
    alias I = ParameterTypeTuple!(Fun [0]) [0];
    alias Msg = ReturnType!(Fun [0]);
       
    static assert (checkFuncReduce!(Fun [1], Msg));    

    alias MapFun = Fun [0];
    alias ReduceFun = Fun [1];
    
          
    Msg  reduce (I [ulong] array) {
	import std.conv;
	array.syncWriteln !((ulong it, I i) => to!string (i.id) ~ ":" ~ to!string (i.rank) ~ ",");
	
	Msg res;
	ulong i = 0;
	foreach (key, value ; array) {
	    if (i == 0) res = MapFun (value);
	    else 
		res = ReduceFun (res, MapFun (value));
	    i++;
	}
	return res;
    }

    Msg reduce (Msg [] array) {
	auto res = array [0];
	foreach (it ; 1 .. array.length)
	    res = ReduceFun (res, array [it]);
	return res;
    }
    
    auto MapReduceVertices (T : DistGraph!(I, E), E) (T a) {
	auto info = Protocol.commInfo (MPI_COMM_WORLD);
	auto res = reduce (a.vertices);
	syncWriteln (res);
	
	Msg [] aux;
	gather (0, info.total, res, aux, MPI_COMM_WORLD);
	if (info.id == 0)
	    res = reduce (aux);	
	return res;	
    }    
}

