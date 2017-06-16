module assign.graph.JoinVertices;
import assign.Job;
import assign.graph.DistGraph;
import assign.data.Data;
import assign.data.AssocArray;
import assign.launching;
import std.traits;
import std.container;
import std.stdio, std.algorithm;


template JoinVertices (alias fun) {
    auto JoinVertices (T : DistGraph!(VD, ED), VD, ED, Msg) (T gp, DistAssocArray!(ulong, Msg) msgs) {
	return JoinVerticesS!(VD, ED, fun) (gp, msgs);
    }
}

template JoinVerticesS (VD, ED, alias fun) {

    alias VO = ReturnType!(fun);
    alias Msg = ParameterTypeTuple!(fun) [1];
    alias DArray = DistAssocArray!(ulong, Msg);
    
    alias thisJob = Job!(joinJob, endJob);
        
    VO [ulong] join (VD [ulong] verts, Msg [ulong] msgs) {
	VO [ulong] _out;
	foreach (key, value ; verts) {
	    auto res = key in msgs;
	    if (res !is null)
		_out [key] = fun (value, *res);
	    else _out [key] = fun (value, Msg.init);
	}
	return _out;
    }

    void joinJob (uint addr, uint idFrom, uint idTo, uint assocId) {
	auto grpFrom = DataTable.get!(DistGraph!(VD, ED)) (idFrom);
	auto grpTo = DataTable.get!(DistGraph!(VO, ED)) (idTo);
	auto assoc = DataTable.get!(DArray) (assocId);	
	grpTo.localVertices = join (grpFrom.localVertices, assoc.local);
	grpTo.localEdges = grpFrom.localEdges;
	Server.jobResult (addr, new thisJob, idTo);
    }

    void endJob (uint addr, uint id) {
	Server.sendMsg (id);
    }

    DistGraph!(VO, ED) JoinVerticesS (T : DistGraph! (VD, ED)) (T gp, DArray values) {
	auto grpTo = new DistGraph! (VO, ED);
	foreach (it ; Server.connected) {
	    Server.jobRequest (it, new thisJob, gp.id, grpTo.id, values.id);
	}
	
	grpTo.localVertices = join (gp.localVertices, values.local);
	grpTo.localEdges = gp.localEdges;
	
	foreach (it ; Server.connected) {
	    Server.waitMsg!(uint);
	}
	
	return grpTo;
    }
    
}
