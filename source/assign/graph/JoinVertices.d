module assign.graph.JoinVertices;
import assign.Job;
import assign.graph.DistGraph;
import assign.data.Data;
import assign.launching;
import std.traits;
import std.container;
import std.stdio, std.algorithm;


template JoinVertices (alias fun) {
    auto JoinVertices (T : DistGraph!(VD, ED), VD, ED, Msg) (T gp, Msg[ulong] msgs) {
	return JoinVerticesS!(VD, ED, fun) (gp, msgs);
    }
}

template JoinVerticesS (VD, ED, alias fun) {

    alias VO = ReturnType!(fun);
    alias Msg = ParameterTypeTuple!(fun) [1];
    
    alias thisJob = Job!(joinJob, endJob);

    struct KV {
	ulong id;
	Msg msg;
    }
    
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

    VO [ulong] join (VD [ulong] verts, KV[] msgs) {
	VO [ulong] _out;
	foreach (key, value ; verts) {
	    auto res = msgs.find!("a.id == b") (key);
	    if (res != []) {
		_out [key] = fun (value, res [0].msg);
	    } else {
		_out [key] = fun (value, Msg.init);
	    }
	}
	
	return _out;
    }
    
    auto toSend (ref Msg [ulong] aux) {
	auto _toSend = new KV [aux.length];
	ulong i = 0;
	foreach (key, value ; aux) {
	    _toSend [i] = KV (key, value);
	    i ++;
	}
	return _toSend;
    }

    void joinJob (uint addr, uint idFrom, uint idTo, KV [] values) {
	auto grpFrom = DataTable.get!(DistGraph!(VD, ED)) (idFrom);
	auto grpTo = DataTable.get!(DistGraph!(VO, ED)) (idTo);
	grpTo.localVertices = join (grpFrom.localVertices, values);
	grpTo.localEdges = grpFrom.localEdges;
	Server.jobResult (addr, new thisJob, idTo);
    }

    void endJob (uint addr, uint id) {
	Server.sendMsg (id);
    }

    DistGraph!(VO, ED) JoinVerticesS (T : DistGraph! (VD, ED)) (T gp, Msg [ulong] values) {
	auto grpTo = new DistGraph! (VO, ED);
	auto kv = toSend (values);
	foreach (it ; Server.connected) {
	    Server.jobRequest (it, new thisJob, gp.id, grpTo.id, kv);
	}
	
	grpTo.localVertices = join (gp.localVertices, values);
	grpTo.localEdges = gp.localEdges;
	
	foreach (it ; Server.connected) {
	    Server.waitMsg!(uint);
	}
	
	return grpTo;
    }
    
}
