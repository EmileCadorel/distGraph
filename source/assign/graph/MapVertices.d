module assign.graph.MapVertices;
import assign.Job;
import assign.graph.DistGraph;
import assign.data.Data;
import assign.launching;
import std.traits;
import std.container;
import std.stdio;


template MapVertices (alias fun) {

    alias VO = ReturnType!(fun);
    
    DistGraph!(VO, E) MapVertices (T : DistGraph! (V, E), V, E) (T a) {
	return MapVerticesVE!(V, E, fun) (a);
    }
    
}

template MapVerticesVE (V, E, alias fun) {

    alias VO = ReturnType!(fun);

    alias thisJob = Job!(mapJob, endJob);

    VO [ulong] map (V [ulong] _in) {
	VO [ulong] _out;
	foreach (key, value ; _in) {
	    _out [key] = fun (value);
	}
	return _out;
    }

    void mapJob (uint addr, uint idFrom, uint idTo) {
	auto grpFrom = DataTable.get!(DistGraph!(V, E)) (idFrom);
	auto grpTo = DataTable.get!(DistGraph!(VO, E)) (idTo);
	grpTo.localVertices = map (grpFrom.localVertices);
	grpTo.localEdges = grpFrom.localEdges;	
	Server.jobResult (addr, new thisJob, idTo);
    }

    void endJob (uint addr, uint id) {
	Server.sendMsg (id);
    }

    DistGraph! (VO, E) MapVerticesVE (T : DistGraph!(V, E)) (T a) {
	auto aux = new DistGraph!(VO, E);
	foreach (it ; Server.connected) {
	    Server.jobRequest (it, new thisJob, a.id, aux.id);	    
	}
	aux.localEdges = a.localEdges;
	aux.localVertices = map (a.localVertices);
	aux.cuts = a.cuts;
	
	foreach (it ; Server.connected) {
	    Server.waitMsg!(uint);
	}
	return aux;
    }        

}
