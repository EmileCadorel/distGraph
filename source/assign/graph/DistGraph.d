module assign.graph.DistGraph;
import assign.data.Data;
import assign.launching;
import assign.Job, assign.cpu;
import std.outbuffer, std.typecons, std.array;
import std.container, std.stdio, std.conv;

struct Vertex {
    ulong id;
}

struct Edge {
    Vertex src;
    Vertex dst;

}

struct VertexD {
    
    private ulong _id;

    this (ulong id) {
	this._id = id;
    }
    
    this (Vertex v) {
	this._id = v.id;
    }

    ulong id () const {
	return this._id;
    }
    
}

struct EdgeD {

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

class DistGraphFragment (VD, ED) {

    // Les sommets du fragments
    private VD [ulong] _vertices;

    // Les arêtes du fragment
    private Array!ED _edges;

    this () {}
    
    void addEdge (Edge edge) {
	static if (is (VD == VertexD)) {
	    this._edges.insertBack (EdgeD (edge));
	    this._vertices [edge.src.id] = VertexD (edge.src);
	    this._vertices [edge.dst.id] = VertexD (edge.dst);
	} else {
	    assert (false);
	}
    }
    
    ulong length () {
	return this._edges.length;
    }

    ref VD [ulong] localVertices () {
	return this._vertices;
    }

    ref Array!ED localEdges () {
	return this._edges;
    }
}


class DistGraph (VD, ED) : DistData {
    import std.traits;
    // on ne stocke que des structures (pas de classe, on veut pouvoir récupérer les données brut)
    static assert (isAggregateType!(VD) && isAggregateType!(ED));
    
    // Les fragment du graphe en mémoire locale
    private DistGraphFragment!(VD, ED) [] _fragments;
    
    // Le nombre d'arête par partitions
    private ulong [uint] _nbEdges;

    /// la pourcentage idéale sur chacune des machines.
    private double [uint] _sizes;

    // La liste des sommets coupé entre différentes machines.
    // Cette liste est temporaire et supprimé lors du finalize.
    private RedBlackTree!(uint) [ulong] _cuts;

    // Liste final de la table des sommets coupé
    // Chaque clé est une paire de machine.
    private ulong[] [Tuple!(uint, uint)] _finalCuts;
    
    private ulong _nbVerts;
    
    alias thisRegJob = Job!(registerJob, endJob);
    alias thisAddJob = Job!(addEdgeJob, endJob);
    alias thisToDotJob = Job!(toDotJob, toDotEnd);
    
    static void registerJob (uint addr, uint id) {
	DataTable.add (new DistGraph!(VD, ED) (id));
	Server.jobResult!(thisRegJob) (addr, id);
    }
    
    static void endJob (uint addr, uint id) {
	Server.sendMsg (id);
    }
       
    this () {
	super (computeId ());
	prepareFrags ();
	auto sizes = Server.getMachinesFreeMemory ();
	this._sizes = computePercents (sizes);
	
	foreach (key, value ; this._sizes) {
	    this._nbEdges [key] = 0;
	}
	
	foreach (it ; Server.connected) {
	    Server.jobRequest!(thisRegJob) (it, this.id);
	}

	foreach (it; Server.connected) {
	    Server.waitMsg!(uint);
	}
    }

    private this (uint id) {
	super (id);
	prepareFrags ();
    }

    void prepareFrags () {
	auto nbFrag = SystemInfo.cpusInfo.length;
	this._fragments = new DistGraphFragment!(VD, ED) [nbFrag];
	foreach (ref it ; this._fragments) {
	    it = new DistGraphFragment!(VD, ED);
	}
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
	static if (is (VD == VertexD)) {
	    auto dg = DataTable.get!(DistGraph!(VD, ED)) (id);		
	    dg.addEdgeLocal (e);
	} else {
	    assert (false);
	}
    }

    /++
     Returns: la liste des fragments du graphe en mémoire locale.
     +/
    DistGraphFragment!(VD, ED)[] locals () {
	return this._fragments;
    }
    
    private void updateRoutes (ulong id, uint machine) {
	auto it = id in this._cuts;
	if (it !is null) {
	    it.insert (machine);
	} else {
	    this._cuts [id] = redBlackTree (machine);
	}
    }

    void addEdgeLocal (Edge edge) {
	ulong total = 0;
	foreach (it ; this._fragments) {
	    total += it.length;
	}
	
	foreach (it ; this._fragments) {
	    if (it.length < total / this._fragments.length) {
		it.addEdge (edge);
		return;
	    }
	}
	
	this._fragments [0].addEdge (edge);
    }
    
    void addEdge (Edge edge) {
	static if (is (VD == VertexD)) {
	    auto info = computePercents (this._nbEdges);
	    foreach (key, value ; info) {
		if (value < this._sizes [key]) {
		    if (key == Server.machineId) {
			addEdgeLocal (edge);
			this._nbEdges [key] ++;
			this.updateRoutes (edge.src.id, Server.machineId);
			this.updateRoutes (edge.dst.id, Server.machineId);
			return ;
		    } else {
			this._nbEdges [key] ++;
			Server.jobRequest!thisAddJob (key, this._id, edge);
			this.updateRoutes (edge.dst.id, key);
			this.updateRoutes (edge.src.id, key);
			return ;
		    }
		}
	    }
	
	
	    // On a ajouter à personne, le graphe est equilibré
	    // Du coup on l'ajoute à la partition locale
	    addEdgeLocal (edge);
	    this._nbEdges [Server.machineId] ++;
	    this.updateRoutes (edge.dst.id, Server.machineId);
	    this.updateRoutes (edge.src.id, Server.machineId);
	} else {
	    assert (false);
	}
    }

    /++
     Returns: la route des sommets coupé par la distribution sur l'environnement     
     +/
    ref auto cuts () {
	return this._finalCuts;
    }

    /++
     Returns: le nombre de sommets dans le graphes total
     +/
    const (ulong) nbVerts () {
	return this._nbVerts;
    }

    
    /++
     Supprime toutes les informations inutile stocké dans le graphe.
     TODO (cette fonction est beaucoup trop lourde, trouver une autre solution).
     +/
    void finalize () {
	foreach (key ; this._cuts.keys ()) {
	    auto current = this._cuts [key].array ();
	    if (current.length != 1) {
		foreach (it ; 1 .. current.length) {
		    auto tu = tuple (current [0], current [it]);
		    auto inside = tu in this._finalCuts;
		    if (inside) *inside ~= [key];
		    else 
			this._finalCuts [tu] = [key];
		}		    		
	    }	    
	}
	this._nbVerts = this._cuts.length;
	this._cuts = null;
    }

    static void toDotJob (uint addr, uint id) {
	import std.conv;
	auto grp = DataTable.get!(DistGraph!(VD, ED)) (id);
	auto buf = new OutBuffer;

	foreach (frag ; grp.locals) {
	    foreach (key, value ; frag._vertices) {
		buf.writefln ("%d [label=\"%d:%s\"]", key, key, value.to!string);
	    }
		
	    foreach (it ; frag._edges) {
		buf.writefln ("%d -> %d", it.src, it.dst);
	    }
	}
	Server.jobResult!(thisToDotJob) (addr, id, buf.toString);
    }

    static void toDotEnd (uint addr, uint id, string msg) {
	Server.sendMsg (msg);
    }
    
    /++
     Ecris le graphe au format Dot dans un buffer
     Params:
     buf = le buffer que l'on veut remplir (le créé si null)
     Returns: un buffer contenant les données locals du graphe sous format .dot
     +/
    OutBuffer toDot (OutBuffer buf = null) {
	import std.conv;
	if (buf is null) buf = new OutBuffer ();

	auto machineId = Server.machineId;
	foreach (key, it ; this._sizes) {
	    if (key != machineId) {	        	       
		Server.jobRequest!(thisToDotJob) (key, this._id);
	    }
	}

	buf.writefln ("digraph G {");

	foreach (frag ; this.locals) {
	    foreach (key, value ; frag._vertices) {
		buf.writefln ("%d [label=\"%d:%s\"]", key, key, value.to!string);
	    }
	    
	    foreach (it ; frag._edges) {
		buf.writefln ("%d -> %d", it.src, it.dst);
	    }
	}

	foreach (key, it; this._sizes) {
	    if (key != machineId) {
		auto res = Server.waitMsg!(string);
		buf.writef ("%s", res);
	    }
	}
	
	buf.writefln ("}");	
	return buf;
    }

    
}
