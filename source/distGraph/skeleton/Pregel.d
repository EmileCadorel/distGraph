module distGraph.skeleton.Pregel;
import distGraph.mpiez.admin;
public import distGraph.skeleton.Register;
import std.traits;
import std.algorithm;
import std.conv;
import distGraph.utils.Options;
import distGraph.dgraph.DistGraph;
import std.typecons, std.array;
import distGraph.skeleton.Compose;

private bool checkFuncMap (alias fun) () {
    isSkeletable!fun;
    
    alias a1 = ParameterTypeTuple! (fun);
    alias r1 = ReturnType!fun;
    static assert (a1.length == 1 &&
		   is (a1[0] : EdgeTriplet!(VD, ED), VD, ED) &&
		   is (r1 : Iterator!Msg, Msg),
		   "On a besoin de : T2 function (T : EdgeTriplet!(VD, ED), VD, ED, T2 : Iterator!Msg, Msg) (T), pas (" ~ a1 [0].stringof ~ " " ~ r1.stringof);
    return true;        
}


private bool checkFuncReduce (alias fun, Msg) () {
    isSkeletable!fun;
    
    alias a1 = ParameterTypeTuple! (fun);
    alias r1 = ReturnType!fun;
    static assert (a1.length == 2 && is (a1[0] == Msg) && is (a1 [1] == Msg) && is (r1 : Msg), "On a besoin de : Msg function (Msg == " ~ Msg.stringof ~ ") (Msg, Msg)");
    return true;        
}

private bool checkFuncProg (alias fun, VD, Msg) () {
    isSkeletable!fun;
    
    alias a1 = ParameterTypeTuple! (fun);
    alias r1 = ReturnType!fun;
    static assert (a1.length == 2 &&
		   is (a1 [0] == VD) &&
		   is (a1 [1] == Msg) && is (r1 == VD),
		   "On a besoin de : VD function (VD : VertexD, Msg == " ~ Msg.stringof ~ ") (VD, Msg) (" ~ r1.stringof ~ " " ~ a1.stringof ~ ")");
    return true;        
}



/++
 + Fonction Pregel
 + Params:
 + Fun = [une fonction de jointure, une fonction de map, une fonction de réduction].
 + Example:
 + -----
 + // DistGraph!(VertexD, EdgeD) grp = ...;
 +
 + auto initGraph = grp.MapVertices!(
 +     (VertexD vd) => vd.id == 0 ? new DstVertex (v.data, 0.0) : 
 +                                  new DstVertex (v.data, float.infinity)
 + );
 + 
 + // Calcul de la distance de 0 vers tout le monde
 + auto sssp = initGraph.Pregel! (
 +     (DstVertex vd, float nDist) => new DstVertex (v.data, min (v.dst, nDist)),
 +     (EdgeTriplet!(DstVertex, EdgeD) ed) {
 +                if (ed.src.dst + 1 < ed.dst.dst) 
 +                    return iterator (ed.dst.id, ed.src.dst + 1);
 +		  else return Iterator!(float).empty;
 +	},
 +     (float a, float b) => min (a, b)
 + ) (float.infinity);
 + -----
 +
 +/
template Pregel (Fun ...)
    if (Fun.length == 3 || Fun.length == 4) {

    static assert (checkFuncMap!(Fun [1]));
    alias Msg = typeof (ReturnType!(Fun [1]).msg);
    alias VD = typeof ((ParameterTypeTuple!(Fun [1]) [0]).src);

    static assert (checkFuncReduce!(Fun [2], Msg));
    static assert (checkFuncProg!(Fun [0], VD, Msg));

    static if (Fun.length == 4) {
	static assert (Fun [3] == true, Fun[3].stringof);
	enum DEBUG = true;
    } else {
	enum DEBUG = false;
    }
    
    alias VProg = Fun [0];
    alias MapFun = Fun [1];
    alias ReduceFun = Fun [2];

    /++
     Tout les process de MPI_COMM_WORLD doivent lancer cette fonction.
     Params:
     gp = le graphe répartie
     initMsg = Le message par défaut à associer au vertex
     maxIter = le nombre d'itération maximal
     +/
    auto Pregel (T : DistGraph!(VD, ED), ED) (T gp, Msg initMsg, ulong maxIter = ulong.max) {
	auto g = gp.MapVertices!((VD v) => VProg (v, initMsg));
	auto messages = g.MapReduceTriplets! (MapFun, ReduceFun);
	
	auto activeMessages = messages.length;
	static if (DEBUG) syncWriteln (messages);
	auto i = 0;
	while (activeMessages > 0 && i < maxIter) {
	    g = g.JoinVertices !(VProg) (messages);

	    auto olds = messages;
	    messages = g.MapReduceTriplets! (MapFun, ReduceFun);	    	    
	    static if (DEBUG) syncWriteln (messages);
	    activeMessages = messages.length;
	    i ++;
	}
	return g;
    }
            
    
}
