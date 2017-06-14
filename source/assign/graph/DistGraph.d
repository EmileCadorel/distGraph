module assign.graph.DistGraph;
import assign.data.Data;
import assign.launching;
import assign.Job;
import std.outbuffer;
import std.container, std.stdio;

struct Vertex {
    ulong id;
}

struct Edge {
    Vertex src;
    Vertex dst;

}

class VertexD {
    
    private ulong _id;

    this (Vertex v) {
	this._id = v.id;
    }

    ulong id () const {
	return this._id;
    }
    
}

class EdgeD {

    private ulong _src;
    private ulong _dst;

    this (Edge v) {
	this._src = v.src.id;
	this._dst = v.dst.id;
    }

    ulong src () const {
	return this._src;
    }

    ulong dst () const {
	return this._dst;
    }
       
}



class DistGraph (VD : VertexD, ED : EdgeD) : DistData {
    
    private VD [ulong] _vertices;

    private Array!ED _edges;

    // Le nombre d'arête par partitions
    private ulong [uint] _nbEdges;

    /// la pourcentage idéale sur chacune des machines.
    private double [uint] _sizes;
    
    alias thisRegJob = Job!(registerJob, endJob);
    alias thisAddJob = Job!(addEdgeJob, endJob);
    
    static void registerJob (uint addr, uint id) {
	DataTable.add (new DistGraph!(VD, ED) (id));
	Server.jobResult (addr, new thisRegJob (), id);
    }
    
    static void endJob (uint addr, uint id) {
	Server.sendMsg (id);
    }
       
    this () {
	super (computeId ());
	auto sizes = Server.getMachinesFreeMemory ();
	this._sizes = computePercents (sizes);
	
	foreach (key, value ; this._sizes) {
	    this._nbEdges [key] = 0;
	}
	
	foreach (it ; Server.connected) {
	    Server.jobRequest (it, new thisRegJob, this.id);
	}

	foreach (it; Server.connected) {
	    Server.waitMsg!(uint);
	}
    }

    private this (uint id) {
	super (id);
    }
       
    static private double [uint] computePercents (ulong [uint] sizes) {
	auto total = 0;
	double [uint] ret;
	foreach (it ; sizes) {
	    total += it;
	}

	foreach (key, it ; sizes) {
	    if (it != 0) 
		ret [key] = (cast (double) it / cast (double) total);
	    else ret [key] = 0;
	}
	return ret;
    }

    static void addEdgeJob (uint addr, uint id, Edge e) {
	import std.conv;
	writeln ("Nouvelle arete ", e.to!string);
	auto dg = DataTable.get!(DistGraph!(VD, ED)) (id);
	dg._edges.insertBack (new EdgeD (e));
	dg._vertices [e.src.id] = new VertexD (e.src);
	dg._vertices [e.dst.id] = new VertexD (e.dst);
    }

    
    void addEdge (Edge edge) {
	auto info = computePercents (this._nbEdges);
	foreach (key, value ; info) {
	    if (value < this._sizes [key]) {
		if (key == Server.machineId) {
		    this._edges.insertBack (new EdgeD (edge));
		    this._vertices [edge.src.id] = new VertexD (edge.src);
		    this._vertices [edge.dst.id] = new VertexD (edge.dst);
		    this._nbEdges [key] ++;
		    return ;
		} else {
		    this._nbEdges [key] ++;
		    Server.jobRequest (key, new thisAddJob, this._id, edge);
		    return ;
		}
	    }
	}
	
	// On a ajouter à personne, le graphe est equilibré
	// Du coup on l'ajoute à la partition locale
	this._edges.insertBack (new EdgeD (edge));
	this._vertices [edge.src.id] = new VertexD (edge.src);
	this._vertices [edge.dst.id] = new VertexD (edge.dst);
	this._nbEdges [Server.machineId] ++;
    }        

    /++
     Ecris le graphe au format Dot dans un buffer
     Params:
     buf = le buffer que l'on veut remplir (le créé si null)
     Returns: un buffer contenant les données locals du graphe sous format .dot
     +/
    OutBuffer toDot (OutBuffer buf = null) {
	if (buf is null) buf = new OutBuffer ();

	buf.writefln ("digraph G {");
	foreach (it ; this._edges) {
	    buf.writefln ("%d -> %d", it.src, it.dst);
	}
	buf.writefln ("}");
	return buf;
    }

    
}
