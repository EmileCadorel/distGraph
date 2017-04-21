module skeleton.MapReduceTriplets;
import mpiez.admin;
public import skeleton.Register;
import std.traits;
import std.algorithm;
import std.conv;
import utils.Options;
import dgraph.DistGraph;
import std.typecons, std.array;
import skeleton.Compose;

private bool checkFuncMap (alias fun) () {
    isSkeletable!fun;
    
    alias a1 = ParameterTypeTuple! (fun);
    alias r1 = ReturnType!fun;
    static assert (a1.length == 1 &&
		   is (a1[0] : Tuple!(VD, "src", VD, "dst", ED, "edge"), VD, ED) &&
		   is (r1 : Tuple!(ulong, "vid", Msg, "msg"), Msg),
		   "On a besoin de : T2 function (T : EdgeTriplet!(VD, ED), VD, ED, T2 != void) (T), pas (" ~ a1 [0].stringof ~ " " ~ r1.stringof);
    return true;        
}


private bool checkFuncReduce (alias fun, Msg) () {
    isSkeletable!fun;
	
    alias a1 = ParameterTypeTuple! (fun);
    alias r1 = ReturnType!fun;
    static assert (a1.length == 2 && is (a1[0] == Msg) && is (a1 [1] == Msg) && is (r1 : Msg), "On a besoin de : Msg function (Msg == " ~ Msg.stringof ~ ") (Msg, Msg)");
    return true;        
}

alias Iterator (Msg) = Tuple!(ulong, "vid", Msg, "msg");
enum EmptyIterator (Msg) = Tuple!(ulong, "vid", Msg, "msg") (ulong.max, Msg.init);

Iterator!Msg iterator (Msg) (ulong id, Msg msg) {
    return Iterator!Msg (id, msg);
}

alias EdgeTriplet (VD : VertexD, ED : EdgeD) = Tuple !(VD, "src", VD, "dst", ED, "edge");

template MapReduceTriplets (Fun ...)
    if (Fun.length == 2) {

    static assert (checkFuncMap!(Fun [0]));
    alias Msg = typeof (ReturnType!(Fun [0]).msg);

    static assert (checkFuncReduce!(Fun [1], Msg));
    alias MapFun = Fun [0];
    alias ReduceFun = Fun [1];

    alias KV = Tuple!(ulong, "key", Msg, "value");
    

    /**
     On itere sur toutes les arêtes et on applique la fonctions de Map.     
     */
    Iterator!Msg[] executeMap (T : DistGraph!(VD, ED), VD, ED) (T gp) {
	import std.parallelism;
	Iterator!Msg [] res = new Iterator!Msg [gp.edges.length];
	foreach (i, it ; parallel(gp.edges)) {
	    auto triplets = EdgeTriplet!(VD, ED) (gp.vertices [it.src], gp.vertices [it.dst], it);
	    res [i] = MapFun (triplets);
	}
	return res;
    }
        
    /**
     Reduction d'un tableau dans le Map des données final
     */
    auto reduce (KV [] left, ref Msg [ulong] aux) {
	import std.parallelism;
	foreach (it ; parallel (left)) {
	    if (it.key == ulong.max) continue;
	    auto inside = (it.key in aux);
	    if (inside) *inside = ReduceFun (*inside, it.value);
	    else aux [it.key] = it.value;
	}
    }

    /**
     Cette fonction est lente mais elle marche
     TODO, Voir comment faire en sorte que les partitions ne communique qu'avec celle avec qui elle sont en lien.     
     */
    auto executeReduce (T : DistGraph!(VD, ED), VD, ED) (Iterator!Msg [] msgs, T gp) {
    	auto info = Protocol.commInfo (MPI_COMM_WORLD);		
    	Msg [ulong] aux;
    	foreach (it ; msgs) {
	    if (it.vid == ulong.max) continue;
    	    auto inside = (it.vid in aux);
    	    if (inside) *inside = ReduceFun (*inside, it.msg);
    	    else aux [it.vid] = it.msg;
	}
	
    	KV [][] otherAux = new KV[] [info.total];
    	auto toSend = new KV [aux.length];
    	ulong i = 0;
    	foreach (key, value ; aux) {	    
    	    toSend [i] = KV (key, value);
    	    i++;
	}
	
    	// On broadcast toutes les données	
    	foreach (pid ; 0 .. info.total) {
    	    if (pid != info.id) {		
    		broadcast (pid, otherAux [pid], MPI_COMM_WORLD);
    	    } else {
    		broadcast (pid, toSend, MPI_COMM_WORLD);
    	    }
	}	

    	// On reduit ce qu'on a recu
    	foreach (it ; otherAux) {
    	    reduce (it, aux);
    	}
	
    	return aux;
    }
    

    auto MapReduceTriplets (T : DistGraph!(VD, ED), VD, ED) (T gp) {
	auto res = executeMap (gp);	
	return executeReduce (res, gp);
    }
    
    

}





