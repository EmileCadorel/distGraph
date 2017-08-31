module distGraph.skeleton.PowerGraph;
import distGraph.mpiez.admin;
public import distGraph.skeleton.Register;
import std.traits;
import std.algorithm;
import std.conv;
import distGraph.utils.Options;
import distGraph.dgraph.DistGraph;
import std.typecons, std.array;
import distGraph.skeleton.Compose;


private bool checkFuncGather (alias fun) () {
    isSkeletable!fun;
    alias a1 = ParameterTypeTuple! fun;
    alias r1 = ReturnType!fun;
    static assert (a1.length == 1 &&
		   is (a1 [0] : EdgeTriplet!(VD, ED), VD, ED) &&
		   is (r1 : Iterator!Msg, Msg),
		   "On a besoin de A function (ED : EdgeTriplet!(VD, ED), VD, ED, A)");
    return true;
}

private bool checkFuncSum (alias fun, Msg) () {
    isSkeletable!fun;
    alias a1 = ParameterTypeTuple!fun;
    alias r1 = ReturnType!fun;
    static assert (a1.length == 2 && is (a1 [0] == Msg) && is (a1 [1] == Msg)
		   && is (r1 == Msg),
		   "On a besoin de A function (A) (A, A)");
    return true;
}

private bool checkFuncApply (alias fun, Msg) () {
    isSkeletable!fun;
    alias a1 = ParameterTypeTuple!fun;
    alias r1 = ReturnType!fun;
    static assert (a1.length == 2 && is (a1 [0] : VertexD) && is (a1 [1] == Msg)
		   && is (r1 == a1 [0]),
		   "On a besoin de VD function (VD, A) (VD, A)");
    return true;
}

/++
 + Fonction de PowerGraph.
 + Params:
 + Fun = [une fonction de map, une fonction de réduction, une fonction de jointure, une fonction d'arret]
 + Example:
 + ----
 + // DistGraph!(DstVertex, EdgeD) grp = ...;
 + // DstVertex contient, la distance en float.
 + 
 + auto pgraph = grp.MapVertices !( 
 +     (VertexD v) => v.id == 0 ? new DstVertex (v.data, 0.0, 1.0) : 
 +                                new DstVertex (v.data, float.infinity, float.infinity)
 + );
 + 
 + //Calcul des distances de 0 vers tout le monde.
 + auto sssp = pgraph.PowerGraph ! (
 +    (EdgeTriplet!(DstVertex, EdgeD) e) => iterator (e.dst.id, e.src.dst + 1),
 +    (float a, float b) => min (a, b),
 +    (DstVertex v, float a) => a < v.dst ? new DstVertex (v.data, a, v.dst) :
 +                                          new DstVertex (v.data, v.dst, a),
 +    (EdgeTriplet!(DstVertex, EdgeD) e) => 
 +                iterator (e.src.id, abs (a.src.dst - a.src.old) > float.epsilon ||
 +                                    e.src.dst == float.infinity)
 + ) (100); // On execute 100 tour.
 + ----
+/
template PowerGraph (Fun ...)
    if (Fun.length == 4) {

    static assert (checkFuncGather!(Fun [0]));
    alias Msg = typeof (ReturnType!(Fun [0]).msg);
    alias ED = ParameterTypeTuple!(Fun [0]) [0];
    
    static assert (checkFuncSum!(Fun [1], Msg));
    static assert (checkFuncApply!(Fun [2], Msg));
    alias VD = ParameterTypeTuple! (Fun [2]) [0];

    static assert (checkFuncGather!(Fun [3]));

    alias GatherFun = Fun [0];
    alias SumFun = Fun [1];
    alias ApplyFun = Fun [2];
    alias ScatterFun = Fun [3];

    /++
     Classe utilisé pour savoir si le sommet est tjrs actif à l'étape X.
     +/
    private class LV : VD {

	bool active;

	this (Vertex v) { super (v); assert (false); }
	
	this (VD e, bool active) {
	    super (e);
	    this.active = active;
	}		
    }    

    /++
     Cette fonction doit être executé par tout le monde
     Params:
     gp = la partitions du process.
     maxIter = le nombre maximal d'iteration (très important)
     +/
    auto PowerGraph (T : DistGraph!(VD, ED), ED) (T gp, ulong maxIter = ulong.max) {
	auto glGraph = gp.MapVertices! ( (VD v) => cast (VD) new LV (v, true) );

	auto i = 0, nbActive = glGraph.MapReduceVertices! ((VD v) => 1, (int a, int b) => a + b);
	while (i < maxIter && nbActive > 0) {
	    auto acc = glGraph.FilterEdgeTriplets! ( (EdgeTriplet! (VD, ED) e) => (cast (LV) e.src).active)
		.MapReduceTriplets! (GatherFun, SumFun);

	    glGraph = glGraph.JoinVertices! (
		(VD v, Msg e) => cast (VD) new LV (ApplyFun (v, e), (cast (LV)v).active)
	    ) (acc);
	    
	    auto active = glGraph.FilterEdgeTriplets! ( (EdgeTriplet! (VD, ED) e) => (cast (LV) e.src).active)
		.MapReduceTriplets! (ScatterFun, (bool a, bool b) => a || b);
	    
	    glGraph = glGraph.JoinVertices! ( (VD v, bool val) => cast (VD) new LV (v, val) ) (active) ;

	    nbActive = glGraph.MapReduceVertices! (
		(VD v) => (cast (LV) v).active ? 1 : 0,
		(int a, int b) => a + b
	    );
	    i++;
	}
		
	return glGraph.MapVertices ! ((VD v) => new VD (v));
    }                
}
