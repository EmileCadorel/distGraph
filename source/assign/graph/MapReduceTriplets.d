module assign.graph.MapReduceTriplets;
import assign.Job;
import assign.graph.DistGraph;
import assign.data.Data;
import assign.launching;
import std.traits;
import std.container;
import std.stdio;

struct Iterator (Msg) {
    ulong vid;
    Msg msg;

    static Iterator!Msg empty () {
	return Iterator!Msg (ulong.max, Msg.init);
    }
}

Iterator!Msg iterator (Msg) (ulong id, Msg msg) {
    return Iterator!Msg (id, msg);
}

template MapReduceTriplets (Fun ...) {
    
    auto MapReduceTriplets (T : DistGraph!(VD, ED), VD, ED) (T gp) {
	return gp.MapReduceTripletsS!(VD, ED, Fun);
    }
}

template MapReduceTripletsS (VD, ED, Fun ...) {

    alias MapFun = Fun [0];
    alias ReduceFun = Fun [1];
    
    alias Msg = typeof (ReturnType!(Fun [0]).msg);

    alias thisMapReduceJob = Job!(mapReduceJob, endJob);
    
    struct KV {
	ulong key;
	Msg value;
    }

    void mapReduceJob (uint addr, uint id) {
	auto gp = DataTable.get!(DistGraph!(VD, ED)) (id);
	auto mp = executeMap (gp);
	auto red = toSend (mp);
	Server.jobResult (addr, new thisMapReduceJob, id, red);
    }

    void endJob (uint addr, uint id, KV [] res) {
	auto aux = cast (shared (KV)*) res.ptr;
	Server.sendMsg (res.length, aux);
    }
    
    auto executeMap (T : DistGraph!(VD, ED)) (T gp) {
	Msg [ulong] res;
	foreach (it; gp.localEdges) {
	    auto val = MapFun (gp.localVertices [it.src], gp.localVertices [it.dst], it);
	    if (val.vid == ulong.max) continue;
	    if (auto inside = val.vid in res) {
		*inside = ReduceFun (*inside, val.msg);		
	    } else {
		res [val.vid] = val.msg;
	    }
	}
	return res;
    }

    auto reducePass (KV [] left, ref Msg [ulong] aux) {
	foreach (it ; left) {
	    if (it.key == ulong.max) continue;
	    if (auto inside = (it.key in aux)) {
		*inside = ReduceFun (*inside, it.value);
	    } else {
		aux [it.key] = it.value;
	    }	    
	}
	return aux;
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

    auto executeReduce (Msg [ulong] aux) {	
	foreach (it ; Server.connected) {
	    shared (KV)* ptr;
	    ulong len;
	    Server.waitMsg (len, ptr);
	    auto res = (cast (KV*) ptr) [0 .. len];
	    reducePass (res, aux);
	}
	return aux;
    }

    auto MapReduceTripletsS (T : DistGraph!(VD, ED)) (T gp) {
	foreach (it ; Server.connected) {
	    Server.jobRequest (it, new thisMapReduceJob, gp.id);
	}
	auto mp = executeMap (gp);
	auto red = executeReduce (mp);
	return red;
    }
    
}
