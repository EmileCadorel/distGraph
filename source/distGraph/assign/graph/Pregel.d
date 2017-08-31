module distGraph.assign.graph.Pregel;
import distGraph.assign.Job;
import distGraph.assign.graph.DistGraph;
import distGraph.assign.data.Data;
import distGraph.assign.data.AssocArray;
import distGraph.assign.graph.MapVertices;
import distGraph.assign.graph.JoinVertices;
import distGraph.assign.graph.MapReduceTriplets;
import distGraph.assign.launching;
import std.traits;
import std.container;

template Pregel (Fun ...) 
    if (Fun.length == 3) {

    alias VProg = Fun [0];
    alias MapFun = Fun [1];
    alias ReduceFun = Fun [2];

    auto Pregel (VD, ED) (DistGraph!(VD, ED) g, ulong maxIter = ulong.max) {
	alias Msg = typeof (Fun [1](VD.init, VD.init, ED.init).msg);    
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
