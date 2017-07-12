module assign.graph.MapReduceTriplets;
import assign.Job;
import assign.graph.DistGraph;
import assign.data.Data;
import assign.data.AssocArray;
import assign.launching;
import std.traits;
import std.container;
import std.concurrency, core.sync.mutex;
import core.sync.barrier;
import std.stdio, core.thread;
import std.functional;

struct Iterator (Msg) {
    ulong vid;
    Msg msg;

    static Iterator!Msg empty () {
	return Iterator!Msg (ulong.max, Msg.init);
    }
}

Iterator!Msg iterator (Msg) (ulong id, Msg msg) {
    return Iterator!Msg (id, msg);
}

template MapReduceTriplets (Fun ...) {
    
    auto MapReduceTriplets (T : DistGraph!(VD, ED), VD, ED) (T gp) {
	return gp.MapReduceTripletsS!(VD, ED, Fun);
    }
}

template MapReduceTripletsS (VD, ED, Fun ...) {

    alias MapFun = binaryFun!(Fun [0]);
    alias ReduceFun = binaryFun!(Fun [1]);
    
    alias Msg = typeof (typeof(MapFun(VD.init, VD.init, ED.init)).msg);

    alias thisMapReduceJob = Job!(mapJob, endJob);
    alias thisGetJob = Job!(getJob, getJobEnd);
    alias thisSetJob = Job!(setJob, noEndJob);
    alias thisReduceJob = Job!(reduceJob, noEndJob);
    alias thisInformJob = Job!(informJob, informJobEnd);
    alias thisSyncJob = Job!(syncJob, syncJobEnd);
    
    alias DArray = DistAssocArray!(ulong, Msg);
    alias FRAG = DistGraphFragment!(VD, ED);
    
    struct KV {
	ulong key;
	Msg value;
    }
    
    static class MapThread : Thread {
	private DArray _assoc;
	private FRAG * _gp;
	private __gshared static ulong __lastId__;
	private ulong _id;
	private static __gshared Mutex __mtx__;
	private static __gshared Barrier __barrier__;
	private static __gshared Msg [ulong][] __page__; 

	static this () {
	    __mtx__ = new Mutex ();
	}
	
	this (FRAG * gp, DArray assoc) {
	    super (&this.run);
	    this._assoc = assoc;
	    this._gp = gp;
	    synchronized {
		this._id = __lastId__;
		__lastId__ ++;
	    }
	}

	/++
	 On va lancer combien de thread ?, ne les lance pas init juste les ressources nécéssaires.
	 Params:
	 nbThreads = le nombre de thread qui vont être lancé
	 +/
	static void willLaunch (ulong nbThreads) {
	    __lastId__ = 0;
	    __barrier__ = new Barrier (cast (uint) nbThreads);
	    __page__ = new Msg[ulong][nbThreads];
	}

	void reduce (ref Msg [ulong] A, Msg[ulong] B) {
	    foreach (key, value ; B) {
		if (auto inside = key in A) {
		    *inside = ReduceFun (value, *inside);
		} else {
		    A [key] = value;
		}
	    }
	}
	
	void run () {
	    foreach (it ; this._gp.localEdges) {
		auto val = MapFun (this._gp.localVertices [it.src], this._gp.localVertices [it.dst], it);
		if (val.vid != ulong.max) {
		    if (auto inside = val.vid in __page__ [this._id]) {
			*inside = ReduceFun (*inside, val.msg);
		    } else {
			__page__ [this._id][val.vid] = val.msg;
		    }
		}
	    }

	    __barrier__.wait ();
	    
	    auto lastNb = cast(long) (__page__.length), nb = lastNb / 2;
	    auto posMod = (long a, long b) => (a % b + b) % b;
	    bool done = false;
	    while (nb >= 1) {
		if (this._id < nb) {
		    auto id = posMod (this._id + nb, nb * 2);
		    __mtx__.lock_nothrow;
		    auto aux = __page__ [id];
		    __mtx__.unlock_nothrow;
		    reduce (__page__ [this._id],  aux);
		}

		if (this._id == 0 && lastNb % 2 == 1) {
		    auto id = lastNb - 1;
		    __mtx__.lock_nothrow;
		    auto aux = __page__ [id];
		    __mtx__.unlock_nothrow;
		    reduce (__page__ [this._id], aux);
		}
		
		lastNb = nb;
		nb /= 2;
		__barrier__.wait ();
	    }

	    if (this._id == 0) {
		this._assoc.local = __page__ [this._id];		
	    }
	}
	
    }

    static void executeMap (T : DistGraph!(VD, ED)) (T gp, ref DArray assoc) {
	import std.datetime;
	auto begin = Clock.currTime;
	MapThread.willLaunch (gp.locals.length);
	auto res = new Thread[] (gp.locals.length);
	foreach (it ; 0 .. gp.locals.length) {
	    res [it] = new MapThread (
		& gp.locals [it],
		assoc
	    ).start ();
	}
	
	foreach (it ; res) {
	    it.join ();
	}
	writeln ("Temps : ", Clock.currTime - begin);
    }
    
    static void mapJob (uint addr, uint gid, uint aid) {	
	auto gp = DataTable.get!(DistGraph!(VD, ED)) (gid);
	auto assoc = DataTable.get!(DArray) (aid);
	executeMap (gp, assoc);
	Server.jobResult!(thisMapReduceJob) (addr, gid);
    }

    static void endJob (uint addr, uint id) {
	Server.sendMsg (id);
    }
    
    static void getJob (uint addr, uint aid, ulong [] ids) {
	auto assoc = DataTable.get!(DArray) (aid);
	auto res = alloc!(KV) (ids.length);
	auto realLen = 0;
	foreach (it ; 0 .. ids.length) {
	    if (auto loc = ids [it] in assoc.local) {
		res [realLen] = KV (ids [it] , *loc);
		realLen ++;
	    } 
	}
	Server.jobResult!(thisGetJob) (addr, aid, res [0 .. realLen]);
    }
       
    static void getJobEnd (uint addr, uint aid, KV [] ids) {
	Server.sendMsg (ids.length, cast (shared (KV)*) ids.ptr);	
    }

    static void executeLocalReduce (uint other, ulong [] ids, ref DArray assoc) {
	Server.jobRequest!(thisGetJob) (other, assoc.id, ids);
	shared (KV)* aux;
	ulong len;

	Server.waitMsg (len, aux);
	if (aux !is null) {
	    auto gets = (cast (KV*) aux) [0 .. len];
	    foreach (it ; gets) {
		if (auto _loc = it.key in assoc.local)
		    *_loc = ReduceFun (*_loc, it.value);
		else
		    assoc.local [it.key] = it.value;
	    }
	}
    }

    static void reduceJob (uint addr, uint aid, KV [] gets) {
	auto assoc = DataTable.get!(DArray) (aid);
	foreach (it ; gets) {
	    if (auto _loc = it.key in assoc.local)
		*_loc = ReduceFun (*_loc, it.value);
	    else
		assoc.local [it.key] = it.value;
	}	
    }    
    
    static void executeRemoteReduce (uint fst, uint scd, ulong [] ids, uint assoc) {
	Server.jobRequest!(thisGetJob) (scd, assoc, ids);
	shared (KV)* aux;
	ulong len;

	Server.waitMsg (len, aux);
	if (aux !is null) {
	    auto gets = (cast (KV*) aux) [0 .. len];
	    Server.jobRequest!(thisReduceJob) (fst, assoc, gets);
	}
    }    
    
    static void setJob (uint addr, uint aid, KV [] ids) {
	auto assoc = DataTable.get!(DArray) (aid);
	foreach (it ; ids) {
	    assoc.local [it.key] = it.value;
	}
    }
    
    static void noEndJob (uint, uint) { assert (false, "Ce job est censé etre asynchrone"); }
    
    static void informLocal (uint other, ulong [] ids, ref DArray assoc) {
	KV [] total = alloc!(KV) (ids.length);
	auto realLen = 0;
	foreach (it ; 0 .. ids.length) {
	    if (auto _loc = ids [it] in assoc.local) {
		total [realLen] = KV (ids [it], *_loc);
		realLen ++;
	    }
	}
	if (realLen != 0)
	    Server.jobRequest!(thisSetJob) (other, assoc.id, total [0 .. realLen]);
	Server.jobRequest!(thisSetJob) (other, assoc.id, alloc!(KV) (0));
    }

    static void informJob (uint addr, uint aid, ulong [] ids) {
	auto assoc = DataTable.get!(DArray) (aid);
	KV [] total = alloc!(KV) (ids.length);
	auto realLen = 0;
	foreach (it ; 0 .. ids.length) {
	    if (auto _loc = ids [it] in assoc.local) {
		total [realLen] = KV (ids [it], *_loc);
		realLen ++;
	    }
	}
	if (realLen != 0) 
	    Server.jobResult!(thisInformJob) (addr, aid, total [0 .. realLen]);
	Server.jobResult!(thisInformJob) (addr, aid, alloc!(KV) (0));
    }

    static void informJobEnd (uint addr, uint aid, KV [] gets) {
	Server.sendMsg (gets.length, cast (shared (KV)*) gets.ptr);
    }
        
    static void informRemote (uint fst, uint scd, ulong [] ids, uint assoc) {
	Server.jobRequest!(thisInformJob) (fst, assoc, ids);
	ulong len; shared (KV) * aux;
	Server.waitMsg (len, aux);
	if (aux !is null) {
	    auto kvs = (cast (KV*) aux) [0 .. len];
	    Server.jobRequest!(thisSetJob) (scd, assoc, kvs);
	}
    }
    
    static void executeReduce (DistGraph!(VD, ED) gp, ref DArray assoc) {
	auto cuts = gp.cuts;
	foreach (key, value ; cuts) {
	    if (key[0] == Server.machineId) {
		executeLocalReduce (key [1], value, assoc);
	    } else if (key [1] == Server.machineId) {
		executeLocalReduce (key [0], value, assoc);
	    } else {
		executeRemoteReduce (key [0], key [1], value, assoc.id);
	    }
	}

	foreach (key, value; cuts) {
	    if (key[0] == Server.machineId) {
		informLocal (key [1], value, assoc);
	    } else if (key [1] == Server.machineId) {
		informLocal (key [0], value, assoc);
	    } else {
		informRemote (key [0], key [1], value, assoc.id);
	    }
	}
    }

    static void syncJob (uint addr, uint id) {
	writeln ("Sync recv");
	stdout.flush ();
	Server.jobResult!(thisSyncJob) (addr, id);
    }
    
    static void syncJobEnd (uint addr, uint id) {
	Server.sendMsg (id);
    }    
    
    auto MapReduceTripletsS (T : DistGraph!(VD, ED)) (T gp) {
	auto result = new DArray;
	// Chaque partie du graphe execute le map
	foreach (it ; Server.connected) {
	    Server.jobRequest!(thisMapReduceJob) (it, gp.id, result.id);
	}

	executeMap (gp, result);
	// On attend la fin du calcul sur les autres machines
	foreach (it ; Server.connected) {
	    Server.waitMsg!(uint);
	}
	
	executeReduce (gp, result);
	writeln ("Reduce end");
	
	// On synchronise tout le monde
	foreach (it; Server.connected) {
	    Server.jobRequest!(thisSyncJob) (it, 0);
	}

	foreach (it ; Server.connected) {
	    Server.waitMsg!(uint);
	}	
	
	return result;
    }
    
}
