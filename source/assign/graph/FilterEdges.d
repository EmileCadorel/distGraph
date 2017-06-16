module assign.graph.FilterEdges;
import assign.Job;
import assign.graph.DistGraph;
import assign.data.Data;
import assign.launching;
import std.traits;
import std.container;
import std.stdio;

template FilterEdges (alias fun) {

    alias E = ParameterTypeTuple!(fun) [0];
    
    DistGraph!(V, E) FilterEdges (T : DistGraph!(V, E), V) (T a) {
	return FilterEdgesVE!(V, E, fun) (a);
    }
    
}


template FilterEdgesVE (V, E, alias fun) {
    
    alias thisJob = Job!(filterJob, endJob);    
    
    void filter (ref DistGraph!(V, E) _out, DistGraph!(V, E) _in) {
	foreach (value ; _in.localEdges) {
	    if (fun (value)) {
		_out.localEdges.insertBack (value);
		_out.localVertices [value.src] = _in.localVertices [value.src];
		_out.localVertices [value.dst] = _in.localVertices [value.dst];
	    }
	}
	_out.cuts = _in.cuts;
    }
    
    void filterJob (uint addr, uint idFrom, uint idTo) {
	auto grpFrom = DataTable.get!(DistGraph!(V, E)) (idFrom);
	auto grpTo = DataTable.get!(DistGraph!(V, E)) (idTo);
	filter (grpTo, grpFrom);
	Server.jobResult (addr, new thisJob, idTo);
    }    
    
    void endJob (uint addr, uint id) {
	Server.sendMsg (id);
    }
            
    DistGraph! (V, E) FilterEdgesVE (T : DistGraph!(V, E)) (T a) {		
	auto aux = new DistGraph!(V, E) ();       
	foreach (it ; Server.connected) 
	    Server.jobRequest (it, new thisJob, a.id, aux.id);

	filter (aux, a);
	foreach (it ; Server.connected) {
	    Server.waitMsg!(uint);
	}
	return aux;
    }
    
}
