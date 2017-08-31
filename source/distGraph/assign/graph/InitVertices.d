module distGraph.assign.graph.InitVertices;
import distGraph.assign.Job;
import distGraph.assign.graph.DistGraph;
import distGraph.assign.data.Data;
import distGraph.assign.launching;
import std.traits;
import std.container;
import std.stdio, core.thread;
import std.functional;

template InitVertices (alias Fun) {
    alias fun = binaryFun!(Fun);
    
    auto InitVertices (T : DistGraph! (V, E), V, E, T2) (T a, T2 val) {
	alias VO = typeof (fun (V.init, T2.init));
	return InitVerticesVE!(VO, V, E, T2, Fun) (a, val);
    }
    
}

template InitVerticesVE (VO, V, E, T2, alias Fun) {
    alias fun = binaryFun!(Fun);
    alias thisJob = Job!(initJob, endJob);
    alias FRAG = DistGraphFragment!(V, E);
    alias FRAG2 = DistGraphFragment!(VO, E);
    
    static class InitThread : Thread {
	private FRAG * _in;
	private FRAG2 * _out;
	private T2 _val;

	this (FRAG * _in, FRAG2 * _out, T2 val) {
	    super (&this.run);
	    this._in = _in;
	    this._out = _out;
	    this._val = val;
	}

	void run () {
	    foreach (key, value ; this._in.localVertices) {
		this._out.localVertices [key] = fun (value, this._val);
	    }
	    this._out.localEdges = this._in.localEdges;
	}	
    }
    
    static void executeInit (ref DistGraph!(VO, E) _out, DistGraph!(V, E) _in, T2 val) {
	auto res = new Thread[] (_in.locals.length);
	foreach (it ; 0 .. res.length) {
	    res [it] = new InitThread (
		&_in.locals [it],
		&_out.locals [it],
		val
	    ).start ();
	}

	foreach (it ; res)
	    it.join ();	
    }
    
    static void initJob (uint addr, uint idFrom, uint idTo, T2 val) {
	auto grpFrom = DataTable.get!(DistGraph!(V, E)) (idFrom);
	auto grpTo = DataTable.get!(DistGraph!(VO, E)) (idTo);
	executeInit (grpTo, grpFrom, val);
	Server.jobResult!(thisJob) (addr, idTo);
    }

    static void endJob (uint addr, uint id) {
	Server.sendMsg (id);
    }

    DistGraph! (VO, E) InitVerticesVE (T : DistGraph!(V, E)) (T a, T2 val) {
	auto aux = new DistGraph!(VO, E);
	foreach (it ; Server.connected) {
	    Server.jobRequest!(thisJob) (it, a.id, aux.id, val);	    
	}

	executeInit (aux, a, val);
	aux.cuts = a.cuts;
	
	foreach (it ; Server.connected) {
	    Server.waitMsg!(uint);
	}
	return aux;
    }        

    

}
