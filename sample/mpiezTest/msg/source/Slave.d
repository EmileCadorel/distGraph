import Proto;
import std.stdio;
import std.container;
import std.array, std.conv;


T findExtrem (alias fun, T) (T [] rng) {
    T ret = rng [0];
    foreach (it ; 1 .. rng.length) {
	if (fun (rng [it], ret)) ret = rng [it];
    }
    return ret;
}

class Slave {

    private Proto _proto;

    private bool _end = false;
    
    private Array!Edge _window;

    private Array!ulong _vertices;

    private static float __lambda__;

    ulong nbEdges;
    
    this (Proto p, float lambda) {
	this._proto = p;
	__lambda__ = lambda;
    }

    void run () {
	while (!this._end) {
	    this._proto.request (0, EDGE);
	    this._proto.edge.receive (0, &this.edgeReceived);
	    if (!this._end && this._window.length % WINDOW_SIZE == 0) {
		partitionWindow ();
		this._window.clear ();
		this._vertices.clear ();
	    } else if (this._end && this._window.length > 0) {
		partitionWindow ();
		this._window.clear ();
		this._vertices.clear ();
	    }
	}
	this._proto.end (0, END);
    }

    private void partitionWindow () {
	this._proto.state (0, (this._vertices.array));
	Vertex [] vertices; ulong [] partitions;
	this._proto.getState.receive (0, vertices, partitions);
	for (int it = 0, vt = 0; it < this._window.length; it ++, vt += 2) {
	    auto u = vertices [vt];
	    auto v = vertices [vt + 1];
	    u.degree ++;
	    v.degree ++;
	    auto p = selectPartitionHDRF (u, v, partitions);
	    this._window [it].color = p;
	}
	this._proto.putState (0, (this._window.array));
    }

    private float balanceScoreHDRF (ulong p, ulong max, ulong min, float lambda, float epsilon) {
	return lambda * (cast (float) max - cast (float) p) /
	    (epsilon + cast (float) max - cast (float) min);
    }
	
    private float g (Vertex v, ulong p, float thetaV) {
	if (!v.isInPartition(p))
	    return 0;
	else return 1 + (1 - thetaV);
    }
	
    private float replicationScoreHDRF (Vertex u, Vertex v, ulong p, float thetaV1, float thetaV2) {
	return g (u, p, thetaV1) + g (v, p, thetaV2);
    }
	
    private ulong selectPartitionHDRF (Vertex u, Vertex v, ulong [] partitions) {
	import std.algorithm, std.typecons, std.math;
	alias Pair = Tuple!(ulong, "p", float, "score");
	float epsilon = 3.;	    
	auto delta1 = u.degree, delta2 = v.degree;
	auto thetaV1 = cast (float) delta1 / cast (float) (delta1 + delta2);
	auto thetaV2 = 1 - thetaV1;
	auto maxP = partitions.findExtrem!((a, b) => a > b);
	auto minP = partitions.findExtrem!((a, b) => a < b);
	Pair maxPart = Pair (0, float.init);
	Pair [] scores = new Pair [partitions.length];
	foreach (it ; 0 .. partitions.length) {
	    auto p = partitions [it];
	    auto rScore = replicationScoreHDRF (u, v, it, thetaV1, thetaV2);
	    auto bScore = balanceScoreHDRF (p, maxP, minP, __lambda__, epsilon);
	    scores [it] = Pair (it, (rScore + bScore) / 2.);
	}
	return scores [].findExtrem!((a, b) => a.score > b.score).p;
    }
    
    
    private void edgeReceived (ubyte * test, ulong len) {
	if (len != 0) {
	    Serializer!(Edge*) serial;
	    serial.ptr = test;
	    this._window.insertBack (*serial.value);
	    this._vertices.insertBack (serial.value.src);
	    this._vertices.insertBack (serial.value.dst);
	    this.nbEdges ++;
	} else {
	    this._end = true;
	}
    }    

}
