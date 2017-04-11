module dgraph.GraphLoader;
import utils.Singleton;
import std.stdio;
import dgraph.Graph, dgraph.Edge;
import std.string, std.conv;
import std.container, std.algorithm;
import dgraph.Partition;


class GraphLoaderS {

    struct SharedState {
	Array!Vertex vertices;
	Array!ulong partitions;

	Vertex getVertex (ulong id) {
	    auto vert = find!"a.id == b" (vertices [], id);
	    return vert [0];
	}
	
    }

    private string _filename;
    private File _file;

    /++ Le graphe en cours de génération. +/
    private __gshared Graph _currentGraph;    

    private static immutable ulong __windowSize__ = 1;

    __gshared static float __lambda__;
    
    Graph fromEdges (string filename, ulong nbPart, float lambda) {
	import std.parallelism;
	this._file = File (filename, "r");
	__lambda__ = lambda;
	this._currentGraph = new Graph;
	this._currentGraph.partitions = make!(Array!Partition) (new Partition [nbPart]);
	foreach (it ; 0 .. this._currentGraph.partitions.length)
	    this._currentGraph.partitions [it] = new Partition (it + 1);
	
	auto ret = this._currentGraph;
	// Ici il va falloir lancer plein plein de thread
	GraphLoaderS.run ();
	this._currentGraph = null;
	return ret;
    }
	
    static void run () {
	Array!Edge window;
	Array!ulong vertices;
	while (true) {
	    if (Edge e = GraphLoader.next ()) {
		window.insertBack (e);
		vertices.insertBack (e.src);
		vertices.insertBack (e.dst);
		if (window.length % __windowSize__ == 0) {
		    partitionWindow (window, vertices);
		    window.clear ();
		    vertices.clear ();
		}
	    } else break;
	}
    }
    
    private {    

	/++
	 Récupération d'une instance de Edge dans le fichier
	 +/
	Edge next () {
	    auto line = this._file.readln ();
	    if (line !is null) {
		line = line.stripLeft;
		if (line.length > 0 && line [0] != '#') {
		    auto nodes = line.split;
		    return new Edge (to!ulong (nodes [0]), to!ulong (nodes [1]));
		} else return next ();		
	    } else return null;
	}

	SharedState getState (ref Array!ulong vertices) {
	    SharedState state;
	    synchronized {
		state.vertices.length = vertices.length;
		foreach (it ; 0 .. vertices.length) {
		    auto v = this._currentGraph.getVertex (vertices [it]);
		    state.vertices [it] = v;
		}

		foreach (pt ; this._currentGraph.partitions) {
		    state.partitions.insertBack (pt.length);
		}
		
	    }
	    return state;
	}

	void putState (SharedState state, Array!Edge edges) {
	    synchronized {	    
		foreach (e ; edges) {
		    this._currentGraph.addEdge (e);
		    foreach (it ; 0 .. state.partitions.length) {
			this._currentGraph.partitions [it].length = state.partitions [it];
		    }
		}
	    }
	}
			
	static float balanceScore (ulong p, ulong max, ulong min) {	    
	    return (cast (float) max - cast (float) p) /
		(1. + cast (float) max - cast (float) min);
	}

	static float replicationScore (Vertex v, Vertex u, ulong p) {
	    auto sr = 0.;	   
	    if (!find (v.partitions [], p + 1).empty) sr += 1.0;
	    if (!find (u.partitions [], p + 1).empty) sr += 1.0;   
	    return sr;
	}

	static float balanceScoreHDRF (ulong p, ulong max, ulong min, float lambda, float epsilon) {
	    return lambda * (cast (float) max - cast (float) p) /
		(epsilon + cast (float) max - cast (float) min);
	}
	
	static float g (Vertex v, ulong p, float thetaV) {
	    if (!v.isInPartition(p + 1))
		return 0;
	    else return 1 + (1 - thetaV);
	}
	
	static float replicationScoreHDRF (Vertex u, Vertex v, ulong p, float thetaV1, float thetaV2) {
	    return g (u, p, thetaV1) + g (v, p, thetaV2);
	}
	
	static ulong selectPartitionHDRF (Vertex u, Vertex v, ref Array!ulong partitions) {
	    import std.algorithm, std.typecons, std.math;
	    alias Pair = Tuple!(ulong, "p", float, "score");
	    float epsilon = 3.;	    
	    auto delta1 = u.degree, delta2 = v.degree;
	    auto thetaV1 = cast (float) delta1 / cast (float) (delta1 + delta2);
	    auto thetaV2 = 1 - thetaV1;
	    auto maxP = partitions [].maxElement;
	    auto minP = partitions [].minElement;
	    Pair maxPart = Pair (0, float.init);
	    Pair [] scores = new Pair [partitions.length];
	    foreach (it ; 0 .. partitions.length) {
		auto p = partitions [it];
		auto rScore = replicationScoreHDRF (u, v, it, thetaV1, thetaV2);
		auto bScore = balanceScoreHDRF (p, maxP, minP, __lambda__, epsilon);
		scores [it] = Pair (it, (rScore + bScore) / 2.);
	    }
	    return scores [].maxElement!"a.score".p;
	}
	
	static ulong selectPartition (Vertex u, Vertex v, ref Array!ulong partitions) {
	    import std.algorithm, std.typecons;
	    alias Pair = Tuple!(ulong, "p", float, "score");
	    auto maxP = partitions [].maxElement;
	    auto minP = partitions [].minElement;
	    Pair [] scores = new Pair [partitions.length];
	    foreach (it ; 0 .. partitions.length) {
		auto p  = partitions [it];
		auto rScore = replicationScore (u, v, it);
		auto bScore = balanceScore (p, maxP, minP);
		scores [it] = Pair (it, rScore + bScore);
	    }
	    return (scores [].maxElement!"a.score").p;
	}
	
	static void partitionWindow (ref Array!Edge window, ref Array!ulong vertices) {
	    auto state = GraphLoader.getState (vertices);
	    foreach (e ; window) {
		auto u = state.getVertex (e.src);		
		auto v = state.getVertex (e.dst);
		u.degree ++;
		v.degree ++;		
		auto p = selectPartitionHDRF (u, v, state.partitions);
		auto add = u.addPartition (p + 1) ? 1 : 0;
		add += v.addPartition (p + 1) ? 1 : 0;
		e.color = p + 1;
		state.partitions [p] += add;
	    }
	    GraphLoader.putState (state, window);
	}

	static bool trigger (ref Array!Edge window) {
	    return window.length > 1;
	}
       	
    }
    
    mixin Singleton!GraphLoaderS;    
}

alias GraphLoader = GraphLoaderS.instance;
