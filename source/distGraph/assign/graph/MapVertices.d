module distGraph.assign.graph.MapVertices;
import distGraph.assign.Job;
import distGraph.assign.graph.DistGraph;
import distGraph.assign.data.Data;
import distGraph.assign.launching;
import std.traits;
import std.container;
import std.stdio, core.thread;


template MapVertices (alias fun) {
    
    auto MapVertices (T : DistGraph! (V, E), V, E) (T a) {	
	return MapVerticesVE!(V, E, fun) (a);
    }
    
}

template MapVerticesVE (V, E, alias fun) {

    alias VO = typeof (fun (V.init));

    alias thisJob = Job!(mapJob, endJob);
    alias FRAG = DistGraphFragment!(V, E);
    alias FRAG2 = DistGraphFragment!(VO, E);
    
    static class MapThread : Thread {
	private FRAG * _in;
	private FRAG2 * _out;

	this (FRAG * _in, FRAG2 * _out) {
	    super (&this.run);
	    this._in = _in;
	    this._out = _out;
	}

	void run () {
	    foreach (key, value ; this._in.localVertices) {
		this._out.localVertices [key] = fun (value);
	    }
	    this._out.localEdges = this._in.localEdges;
	}	
    }
    
    static void executeMap (ref DistGraph!(VO, E) _out, DistGraph!(V, E) _in) {
	auto res = alloc!(Thread) [_in.locals.length];
	foreach (it ; 0 .. res.length) {
	    res [it] = new MapThread (
		&_in.locals [it],
		&_out.locals [it]
	    ).start ();
	}

	foreach (it ; res)
	    it.join ();	
    }
    
    static void mapJob (uint addr, uint idFrom, uint idTo) {
	auto grpFrom = DataTable.get!(DistGraph!(V, E)) (idFrom);
	auto grpTo = DataTable.get!(DistGraph!(VO, E)) (idTo);
	executeMap (grpTo, grpFrom);
	Server.jobResult!(thisJob) (addr, idTo);
    }

    static void endJob (uint addr, uint id) {
	Server.sendMsg (id);
    }

    DistGraph! (VO, E) MapVerticesVE (T : DistGraph!(V, E)) (T a) {
	auto aux = new DistGraph!(VO, E);
	foreach (it ; Server.connected) {
	    Server.jobRequest!(thisJob) (it, a.id, aux.id);	    
	}

	executeMap (aux, a);
	aux.cuts = a.cuts;
	
	foreach (it ; Server.connected) {
	    Server.waitMsg!(uint);
	}
	return aux;
    }        

}
