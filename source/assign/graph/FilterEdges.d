module assign.graph.FilterEdges;
import assign.Job;
import assign.graph.DistGraph;
import assign.data.Data;
import assign.launching;
import std.traits, core.thread;
import std.container, assign.cpu;
import std.stdio, std.concurrency;

template FilterEdges (alias fun) {

    alias E = ParameterTypeTuple!(fun) [0];
    
    DistGraph!(V, E) FilterEdges (T : DistGraph!(V, E), V) (T a) {
	return FilterEdgesVE!(V, E, fun) (a);
    }    
}

template FilterEdgesVE (V, E, alias fun) {
    
    alias thisJob = Job!(filterJob, endJob);    
    alias FRAG = DistGraphFragment!(V, E);
    
    class FilterThread : Thread {
	private FRAG * _out;
	private FRAG * _in;
	
	this (FRAG* _in, FRAG* _out) {
	    super (&this.run);
	    this._out = _out;
	    this._in = _in;
	}

	void run () {
	    foreach (value ; _in.localEdges) {
		if (fun (value)) {
		    _out.localEdges.insertBack (value);
		    _out.localVertices [value.src] = _in.localVertices [value.src];
		    _out.localVertices [value.dst] = _in.localVertices [value.dst];
		}
	    }
	}
    }
        
    void filter (ref DistGraph!(V, E) _out, DistGraph!(V, E) _in) {
	auto res = new Thread [_in.locals.length];
	foreach (it ; 0 .. _in.locals.length) {
	    res [it] = new FilterThread (
		&_in.locals [it],
		&_out.locals [it]
	    ).start ();
	}
	
	foreach (it ; res)
	    it.join ();
	
	_out.cuts = _in.cuts;
    }
    
    void filterJob (uint addr, uint idFrom, uint idTo) {
	auto grpFrom = DataTable.get!(DistGraph!(V, E)) (idFrom);
	auto grpTo = DataTable.get!(DistGraph!(V, E)) (idTo);
	filter (grpTo, grpFrom);
	Server.jobResult!(thisJob) (addr, idTo);
    }    
    
    void endJob (uint addr, uint id) {
	Server.sendMsg (id);
    }
            
    DistGraph! (V, E) FilterEdgesVE (T : DistGraph!(V, E)) (T a) {		
	auto aux = new DistGraph!(V, E) ();       
	foreach (it ; Server.connected) 
	    Server.jobRequest!(thisJob) (it, a.id, aux.id);

	filter (aux, a);
	foreach (it ; Server.connected) {
	    Server.waitMsg!(uint);
	}
	return aux;
    }
    
}
