module distGraph.assign.graph.JoinVertices;
import distGraph.assign.Job;
import distGraph.assign.graph.DistGraph;
import distGraph.assign.data.Data;
import distGraph.assign.data.AssocArray;
import distGraph.assign.launching;
import std.traits;
import std.container, core.thread;
import std.functional;
import std.stdio, std.algorithm;


template JoinVertices (alias Fun) {

    alias fun = binaryFun!(Fun);
    
    auto JoinVertices (T : DistGraph!(VD, ED), VD, ED, Msg) (T gp, DistAssocArray!(ulong, Msg) msgs) {
	return JoinVerticesS!(VD, ED, Msg, fun) (gp, msgs);
    }
}


template JoinVerticesS (VD, ED, Msg, alias fun) {
    alias VO = typeof (fun (VD.init, Msg.init));    
    alias DArray = DistAssocArray!(ulong, Msg);
    
    alias thisJob = Job!(joinJob, endJob);
    alias FRAG = DistGraphFragment!(VD, ED);
    alias FRAG2 = DistGraphFragment!(VO, ED);

    static class JoinThread : Thread {
	private FRAG * _in;
	private FRAG2 * _out;
	private Msg[ulong] _msgs;

	this (FRAG * _in, FRAG2 * _out, Msg [ulong] msgs) {
	    super (&this.run);
	    this._in = _in;
	    this._out = _out;
	    this._msgs = msgs;
	}

	void run () {
	    foreach (key, value; this._in.localVertices) {
		Msg * res;
		synchronized res = key in this._msgs;
		if (res !is null) {
		    Msg val;
		    synchronized val = *res;
		    this._out.localVertices [key] = fun (value, val);
		} else {
		    static if (is (VD == VO))
			this._out.localVertices [key] = value;
		    else
			this._out.localVertices [key] = fun (value, Msg.init);
		}
	    }
	    this._out.localEdges = this._in.localEdges;	    
	}	
    }
    
    static void join (ref DistGraph!(VO, ED) _out, DistGraph!(VD, ED) _in, Msg [ulong] msgs) {
	auto res = new Thread[] (_in.locals.length);
	auto msgsS = cast (shared(Msg[ulong])*) &msgs;
	foreach (it ; 0 .. _in.locals.length) {
	    res [it] = new JoinThread (
		&_in.locals [it],
		&_out.locals [it],
		msgs
	    ).start ();
	}

	foreach (it ; res)
	    it.join ();
	
	_out.cuts = _in.cuts;
    }
    
    static void joinJob (uint addr, uint idFrom, uint idTo, uint assocId) {
	auto grpFrom = DataTable.get!(DistGraph!(VD, ED)) (idFrom);
	auto grpTo = DataTable.get!(DistGraph!(VO, ED)) (idTo);
	auto assoc = DataTable.get!(DArray) (assocId);
	join (grpTo, grpFrom, assoc.local);
	Server.jobResult!(thisJob) (addr, idTo);
    }

    static void endJob (uint addr, uint id) {
	Server.sendMsg (id);
    }

    DistGraph!(VO, ED) JoinVerticesS (T : DistGraph! (VD, ED)) (T gp, DArray values) {
	auto grpTo = new DistGraph! (VO, ED);
	foreach (it ; Server.connected) {
	    Server.jobRequest!(thisJob) (it, gp.id, grpTo.id, values.id);
	}
	
	join (grpTo, gp, values.local);
	
	foreach (it ; Server.connected) {
	    Server.waitMsg!(uint);
	}
	
	return grpTo;
    }
    
}
