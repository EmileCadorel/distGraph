import std.stdio;
import mpiez.admin;
import dgraph.Vertex, dgraph.Edge;
import std.string, std.conv, std.array;
import std.container, std.algorithm;
import dgraph.Graph;
import utils.Options;

__gshared immutable __windowSize__ = 5;

ulong [] serialize (Vertex v) {
    import std.array;
    return [v.id, v.degree] ~ v.partitions.array;
}

Vertex deserialize (T : Vertex) (ulong [] vals) {
    auto ret = new Vertex (vals [0]);
    ret.degree = vals [1];
    ret.partitions = make!(Array!ulong) (vals [2 .. $]);
    return ret;
}

ulong [] serialize (Edge e) {
    if (e)
	return [e.src, e.dst, e.color];
    else return [];
}

ulong [] serialize (Array!Edge edges) {
    auto ret = [edges.length];
    foreach (it ; edges) {
	ret ~= serialize (it);
    }
    return ret;
}

Edge deserialize (T: Edge) (ulong [] vals) {
    if (vals.length == 3)
	return new Edge (vals [0], vals [1], vals [2]);
    else return null;
}

Array!Edge deserialize(T : Array!Edge) (ulong [] vals) {
    auto nb = vals [0];
    auto ret = new Edge [nb];
    for (ulong i = 1, j = 0 ; i < vals.length ; i += 3, j++) {
	ret [j] = deserialize!Edge (vals [i .. i + 3]);
    }
    return make!(Array!Edge) (ret);
}

ulong [] serialize (SharedState state) {
    auto nb = state.vertices.length;
    auto ret = [nb];
    foreach (it ; 0 .. nb) {
	auto vert = serialize (state.vertices [it]);
	ret ~= [vert.length] ~ vert;
    }
    auto nb2 = state.partitions.length;
    ret ~= state.partitions.array;
    return ret;
}

SharedState deserialize (T : SharedState) (ulong [] vals) {
    auto nb = vals [0];
    auto current = 1;
    Array!Vertex ret;
    foreach (it ; 0 .. nb) {
	auto len = vals [current];
	ret.insertBack (deserialize!Vertex (vals [current + 1 .. current + 1 + len]));
	current += len + 1;
    }
    
    return new SharedState (ret, make!(Array!ulong) (vals [current .. $]));
    
}

enum EDGE = 0;
enum STATE = 1;
enum PUT = 2;
enum END = 3;

class Proto : Protocol {

    this (int id, int total) {
	super (id, total);
	this.edge = new Message!(0, ulong[]);
	this.request = new Message!(1, int, int);
	this.state = new Message!(2, ulong[]);
	this.put = new Message !(3, ulong[], ulong[]);
    }

    Message!(0, ulong[]) edge;

    // procId, type
    Message!(1, int, int) request;

    // vertices
    Message!(2, ulong[]) state;

    // state, edges
    Message!(3, ulong [], ulong[]) put;
}

class SharedState {
    Array!Vertex vertices;
    Array!ulong partitions;

    this () {}
    this (Array!Vertex vert, Array!ulong partitions) {
	this.vertices = vert;
	this.partitions = partitions;
    }
    
    Vertex getVertex (ulong id) {
	auto vert = find!"a.id == b" (vertices [], id);
	return vert [0];
    }
}

class Session : Process!Proto {

    this (Proto p) {
	super (p);
	__lambda__ = to!float (Options ["-l"]);
	__nbPart__ = to!ulong (Options ["-n"]);
	__file__ = Options ["-i"];
    }

    override void routine () {
	if (this._proto.id == 0) {
	    master ();
	} else {
	    run ();
	}
    }

    private Edge next () {
	auto line = this._file.readln ();
	if (line !is null) {
	    line = line.stripLeft;
	    if (line.length > 0 && line [0] != '#') {
		auto nodes = line.split;
		return new Edge (to!ulong (nodes [0]), to!ulong (nodes [1]));
	    } else return next ();		
	} else return null;
    }
    
    private SharedState computeState (ulong [] vertices) {
	SharedState state = new SharedState;
	state.vertices = make!(Array!Vertex)(new Vertex [vertices.length]);
	foreach (it ; 0 .. vertices.length) {
	    auto v = this._current.getVertex (vertices [it]);
	    state.vertices [it] = v;
	}
	
	foreach (pt ; this._current.partitions) {
	    state.partitions.insertBack (pt.length);
	}
	
	return state;
    }

    private void updateState (SharedState state, Array!Edge edges) {
	foreach (e ; edges) {
	    this._current.addEdge (e);
	}
	
	foreach (vt ; state.vertices) {
	    auto v = this._current.getVertex (vt.id);
	    foreach (pt ; vt.partitions)
		v.addPartition (pt);
	}
	
	foreach (it; 0 .. state.partitions.length) {
	    this._current.partitions [it].length = state.partitions [it];
	}
    }    
    
    private void master () {
	this._file = File (__file__, "r");
	this._current = new Graph ();
	this._current.partitions = make!(Array!Partition)(new Partition [__nbPart__]);
	foreach (it ; 0 .. __nbPart__) this._current.partitions [it] = new Partition (it);
	ulong nb = 0;
	while (true) {
	    int procId, type;
	    this._proto.request.receive (procId, type);
	    if (type == EDGE) {
		auto edge = serialize (next ());
		this._proto.edge (procId, edge);
	    } else if (type == STATE) {
		ulong [] vertices;
		//writeln ("Debut State", procId);
		this._proto.state.receive (procId, vertices);
		this._proto.state (procId, serialize (computeState (vertices)));
		//writeln ("Fin State", procId);
	    } else if (type == PUT) {
		ulong [] state, edges;
		//writeln ("Debut Put", procId);
		this._proto.put.receive (procId, state, edges);
		updateState (deserialize!SharedState (state), deserialize!(Array!Edge) (edges));
		//writeln ("Fin Put ", procId);
	    } else if (type == END) {
		nb ++;
		writefln ("END %d", procId);
		if (nb == this._proto.total - 1) break;
	    }
	}
    }    

    private Edge nextLocal () {
	ulong [] res;
	this._proto.request (0, this._proto.id, EDGE);
	this._proto.edge.receive (0, res);
	return deserialize!Edge (res);
    }

    private SharedState requestState (Array!ulong vertices) {
	this._proto.request (0, this._proto.id, STATE);
	this._proto.state (0, vertices.array);
	ulong [] state;
	this._proto.state.receive (0, state);
	return deserialize!SharedState (state);
    }

    private void putState (SharedState state, Array!Edge edges) {
	this._proto.request (0, this._proto.id, PUT);
	this._proto.put (0, serialize (state), serialize (edges));	
    }
    
    private void run () {
	Array!Edge window;
	Array!ulong vertices;
	while (true) {
	    if (Edge e = nextLocal ()) {
		window.insertBack (e);
		vertices.insertBack (e.src);
		vertices.insertBack (e.dst);
		if (window.length % __windowSize__ == 0) {
		    partitionWindow (window, vertices);
		    window.clear ();
		    vertices.clear ();
		}
	    } else {
		this._proto.request (0, this._proto.id, END);
		break;
	    }
	}
    }

    private float balanceScoreHDRF (ulong p, ulong max, ulong min, float lambda, float epsilon) {
	return lambda * (cast (float) max - cast (float) p) /
	    (epsilon + cast (float) max - cast (float) min);
    }
	
    private float g (Vertex v, ulong p, float thetaV) {
	if (!v.isInPartition(p + 1))
	    return 0;
	else return 1 + (1 - thetaV);
    }
	
    private float replicationScoreHDRF (Vertex u, Vertex v, ulong p, float thetaV1, float thetaV2) {
	return g (u, p, thetaV1) + g (v, p, thetaV2);
    }
	
    private ulong selectPartitionHDRF (Vertex u, Vertex v, ref Array!ulong partitions) {
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
    
    private void partitionWindow (Array!Edge window, Array!ulong vertices) {
	auto state = requestState (vertices);
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
	putState (state, window);
    }    

    override void onEnd () {
	if (this._proto.id == 0) {
	    auto a = this._current;
	    auto score = 0;
	    foreach (vt ; a.vertices) {
		if (vt && vt.partitions.length > 0) {
		    write (vt.id, "-> [");
		    if (vt.partitions.length > 1)
			score++;
		    foreach (pt; vt.partitions)
			write (pt, pt !is vt.partitions [$ - 1] ? ", " : "");
		    writeln ("]");
		}
	    }

	    writeln ("Ratio : ", cast (float) score / cast (float) a.vertices.length, " -> ",
		     score, "/", a.vertices.length);

	    auto file = File ("out.dot", "w+");	
	    file.write (this._current.toDot (null, true).toString ());
	    file.close ();
	}	
	syncFunc (function (int id) {
		writefln ("End of process %d", id);
	    }, this._proto.id);
    }

    private File _file;

    private Graph _current;

    static float __lambda__ = 1.9;
    static ulong __nbPart__ = 2;
    static string __file__;
}

void main(string [] args) {    
    Admin!Session adm = new Admin!Session (args);
    adm.finalize ();
}
