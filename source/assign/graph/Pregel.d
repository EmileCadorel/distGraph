module assign.graph.Pregel;
import assign.Job;
import assign.graph.DistGraph;
import assign.data.Data;
import assign.data.AssocArray;
import assign.graph.MapVertices;
import assign.graph.JoinVertices;
import assign.graph.MapReduceTriplets;
import assign.launching;
import std.traits;
import std.container;

template Pregel (Fun ...) 
    if (Fun.length == 3) {

    alias Msg = typeof (ReturnType!(Fun [1]).msg);    
    alias VProg = Fun [0];
    alias MapFun = Fun [1];
    alias ReduceFun = Fun [2];

    auto Pregel (VD, ED) (DistGraph!(VD, ED) g, ulong maxIter = ulong.max) {
	auto messages = g.MapReduceTriplets!(MapFun, ReduceFun);
	
	ulong activeMessages = messages.length;
	auto i = 0UL;
	
	while (activeMessages > 0 && i < maxIter) {
	    g = g.JoinVertices!(VProg) (messages);
	    auto olds = messages;

	    messages = g.MapReduceTriplets!(MapFun, ReduceFun);
	    activeMessages = messages.length;
	    i++;
	}
	return g;
    }
    
    
}
