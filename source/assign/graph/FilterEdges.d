module assign.graph.FilterEdges;
import assign.Job;
import assign.graph.DistGraph;
import assign.data.Data;
import assign.launching;
import std.traits;
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

    void filterThread (Tid owner, shared (DistGraph!(V, E))* _outS, shared (DistGraph!(V, E)*) _inS, ulong begin, ulong len) {
	auto _out = cast (DistGraph!(V, E)*) _outS;
	auto _in = cast (DistGraph!(V, E)*) _inS;
	foreach (it; 0 .. len) {
	    auto value = _in.localEdges [it + begin];
	    if (fun (value)) {
		synchronized {
		    _out.localEdges.insertBack (value);
		    _out.localVertices [value.src] = _in.localVertices [value.src];
		    _out.localVertices [value.dst] = _in.localVertices [value.dst];
		}
	    }
	}
	send (owner, true);
    }
    
    void filter (ref DistGraph!(V, E) _out, DistGraph!(V, E) _in) {
	auto nb = SystemInfo.cpusInfo.length;
	auto res = new Tid [nb - 1];
	foreach (it ; 0 .. nb - 1) {
	    res [it] = spawn (&filterThread,
			      thisTid,
			      cast (shared (DistGraph!(V, E))*) &_out,
			      cast (shared (DistGraph!(V, E))*) &_in,
			      (_in.localEdges.length / nb) * it,
			      (_in.localEdges.length / nb) * (it + 1)
	    );
	}
	
	foreach (it ; (_in.localEdges.length / nb) * (nb - 1) .. _in.localEdges.length) {
	    auto value = _in.localEdges [it];
	    if (fun (value)) {
		synchronized {
		    _out.localEdges.insertBack (value);
		    _out.localVertices [value.src] = _in.localVertices [value.src];
		    _out.localVertices [value.dst] = _in.localVertices [value.dst];
		}
	    } 
	}
	
	foreach (it ; 0 .. nb - 1) {
	    receiveOnly!(bool);
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
