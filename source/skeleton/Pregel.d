module skeleton.Pregel;
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
