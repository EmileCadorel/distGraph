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
		   is (a1[0] : EdgeTriplet!(VD, ED), VD, ED) &&
		   is (r1 : Iterator!Msg, Msg),
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

struct Iterator (Msg) if (!is (Msg : Object)) {
    ulong vid;
    Msg msg;

    static Iterator!Msg empty () {
	return Iterator!Msg (ulong.max, Msg.init);
    }
}

Iterator!Msg iterator (Msg) (ulong id, Msg msg) {
    return Iterator!Msg (id, msg);
}

struct EdgeTriplet (VD : VertexD, ED : EdgeD) {
    VD src, dst;
    ED edge;
}

template MapReduceTriplets (Fun ...)
    if (Fun.length == 2) {

    static assert (checkFuncMap!(Fun [0]));
    alias Msg = typeof (ReturnType!(Fun [0]).msg);

    static assert (checkFuncReduce!(Fun [1], Msg));
    alias MapFun = Fun [0];
    alias ReduceFun = Fun [1];

    struct KV {
	ulong key;
	Msg value;
    }   

    class Proto : Protocol {

	this (int id, int total) {
	    super (id, total);
	    this.msg = new Message !(1, KV []);
	}

	Message!(1, KV []) msg;
    }
   
    /**
     On itere sur toutes les arêtes et on applique la fonctions de Map.     
     */
    auto executeMap (T : DistGraph!(VD, ED), VD, ED) (T gp) {
	Msg [ulong] res;
	foreach (it ; gp.edges) {
	    auto val = MapFun (EdgeTriplet!(VD, ED) (gp.vertices [it.src], gp.vertices [it.dst], it));
	    if (val.vid == ulong.max) continue;
	    if (auto inside = val.vid in res) {
		*inside = ReduceFun (*inside, val.msg);// MapFun (it);
	    } else {
		res [val.vid] = val.msg;
	    }
	}
	return res;
    }
        
    /**
     Reduction d'un tableau dans le Map des données final
     */
    auto reduce (KV [] left, ref Msg [ulong] aux) {
	foreach (it ; left) {
	    if (it.key == ulong.max) continue;
	    auto inside = (it.key in aux);
	    if (inside) *inside = ReduceFun (*inside, it.value);
	    else aux [it.key] = it.value;
	}
	return aux;
    }

    auto toSend (ref Msg [ulong] aux) {
	auto _toSend = new KV [aux.length];
    	ulong i = 0;
    	foreach (key, value ; aux) {	    
    	    _toSend [i] = KV (key, value);
    	    i++;
	}
	return _toSend;
    }
    
    /**
     Cette fonction est lente mais elle marche
     TODO, Voir comment faire en sorte que les partitions ne communique qu'avec celle avec qui elle sont en lien.     
     */
    auto executeReduce (T : DistGraph!(VD, ED), VD, ED) (Msg [ulong] aux, T gp) {
    	auto info = Protocol.commInfo (MPI_COMM_WORLD);
	auto proto = new Proto (info.id, info.total);

	// On peut le faire en système de cercle
	/+
	 0 --- 1 --- 2 --- 3 --- 4
	 nb = total / 2
	 tant que nb > 0:
	      si rank < nb:
	         msg <= rank + nb ([0:2, 1:3, 2:4] [0:2] [0:1])
	      sinon 
	         msg => rank - nb
	      nb /= 2
	      
	 +/
	import std.stdio, std.format;
	int nb = (info.total) / 2;

	auto posMod = (int a, int b) => (a % b + b) % b;
	bool done = false;
	int lastNb = (info.total);
	while (nb >= 1) {
	    if (info.id < nb) {
		KV [] res;
		proto.msg.receive (posMod (info.id + nb, nb * 2), res);
		aux = reduce (res, aux);
	    } else if (info.id == (lastNb - 1) && lastNb % 2 == 1) {
		proto.msg (0, toSend (aux));
		done = true;		
	    } else if (!done) {
		done = true;
		proto.msg (posMod (info.id - nb, nb * 2), toSend (aux));
	    }
	    
	    if (info.id == 0 && lastNb % 2 == 1) {
		KV [] res;
		proto.msg.receive (lastNb - 1, res);
		aux = reduce (res, aux);
	    }
	    
	    lastNb = nb;
	    nb /= 2;
	}

	KV [] res;
	if (info.id == 0) res = toSend (aux);
	broadcast (0, res, MPI_COMM_WORLD);
	return reduce (res, aux);
    }
    

    auto MapReduceTriplets (T : DistGraph!(VD, ED), VD, ED) (T gp) {
	auto mp = executeMap (gp);
	auto red = executeReduce (mp, gp);
	return red;	
    }
   
}



