module assign.graph.MapReduceTriplets;
import assign.Job;
import assign.graph.DistGraph;
import assign.data.Data;
import assign.data.AssocArray;
import assign.launching;
import std.traits;
import std.container;
import std.stdio, core.thread;

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

    alias MapFun = Fun [0];
    alias ReduceFun = Fun [1];
    
    alias Msg = typeof (ReturnType!(Fun [0]).msg);

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
    
    class MapThread : Thread {
	private DArray _assoc;
	private FRAG * _gp;

	this (FRAG * gp, DArray assoc) {
	    super (&this.run);
	    this._assoc = assoc;
	    this._gp = gp;
	}

	void run () {
	    foreach (it ; this._gp.localEdges) {
		auto val = MapFun (this._gp.localVertices [it.src], this._gp.localVertices [it.dst], it);
		if (val.vid == ulong.max) continue;
		synchronized {
		    if (auto inside = val.vid in this._assoc.local) {
			*inside = ReduceFun (*inside, val.msg);
		    } else {
			this._assoc.local [val.vid] = val.msg;
		    }
		}
	    }
	}
	
    }

    void executeMap (T : DistGraph!(VD, ED)) (T gp, ref DArray assoc) {
	auto res = new Thread [gp.locals.length];
	foreach (it ; 0 .. gp.locals.length) {
	    res [it] = new MapThread (
		& gp.locals [it],
		assoc
	    ).start ();
	}

	foreach (it ; res) {
	    it.join ();
	}	
    }
    
    void mapJob (uint addr, uint gid, uint aid) {	
	auto gp = DataTable.get!(DistGraph!(VD, ED)) (gid);
	auto assoc = DataTable.get!(DArray) (aid);
	executeMap (gp, assoc);
	Server.jobResult (addr, new thisMapReduceJob, gid);
    }

    void endJob (uint addr, uint id) {
	Server.sendMsg (id);
    }
    
    void getJob (uint addr, uint aid, ulong [] ids) {
	auto assoc = DataTable.get!(DArray) (aid);
	auto res = new KV [ids.length];
	auto realLen = 0;
	foreach (it ; 0 .. ids.length) {
	    if (auto loc = ids [it] in assoc.local) {
		res [realLen] = KV (ids [it] , *loc);
		realLen ++;
	    } 
	}
	Server.jobResult (addr, new thisGetJob, aid, res [0 .. realLen]);
    }
       
    void getJobEnd (uint addr, uint aid, KV [] ids) {
	Server.sendMsg (ids.length, cast (shared (KV)*) ids.ptr);	
    }

    void executeLocalReduce (uint other, ulong [] ids, ref DArray assoc) {
	Server.jobRequest (other, new thisGetJob, assoc.id, ids);
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

    void reduceJob (uint addr, uint aid, KV [] gets) {
	auto assoc = DataTable.get!(DArray) (aid);
	foreach (it ; gets) {
	    if (auto _loc = it.key in assoc.local)
		*_loc = ReduceFun (*_loc, it.value);
	    else
		assoc.local [it.key] = it.value;
	}	
    }    
    
    void executeRemoteReduce (uint fst, uint scd, ulong [] ids, uint assoc) {
	Server.jobRequest (scd, new thisGetJob, assoc, ids);
	shared (KV)* aux;
	ulong len;

	Server.waitMsg (len, aux);
	if (aux !is null) {
	    auto gets = (cast (KV*) aux) [0 .. len];
	    Server.jobRequest (fst, new thisReduceJob, assoc, gets);
	}
    }    
    
    void setJob (uint addr, uint aid, KV [] ids) {
	auto assoc = DataTable.get!(DArray) (aid);
	foreach (it ; ids) {
	    assoc.local [it.key] = it.value;
	}
    }
    
    void noEndJob (uint, uint) { assert (false, "Ce job est censé etre asynchrone"); }
    
    void informLocal (uint other, ulong [] ids, ref DArray assoc) {
	KV [] total = new KV [ids.length];
	auto realLen = 0;
	foreach (it ; 0 .. ids.length) {
	    if (auto _loc = ids [it] in assoc.local) {
		total [realLen] = KV (ids [it], *_loc);
		realLen ++;
	    }
	}
	if (realLen != 0)
	    Server.jobRequest (other, new thisSetJob, assoc.id, total [0 .. realLen]);
	Server.jobRequest (other, new thisSetJob, assoc.id, new KV [0]);
    }

    void informJob (uint addr, uint aid, ulong [] ids) {
	auto assoc = DataTable.get!(DArray) (aid);
	KV [] total = new KV [ids.length];
	auto realLen = 0;
	foreach (it ; 0 .. ids.length) {
	    if (auto _loc = ids [it] in assoc.local) {
		total [realLen] = KV (ids [it], *_loc);
		realLen ++;
	    }
	}
	if (realLen != 0) 
	    Server.jobResult (addr, new thisInformJob, aid, total [0 .. realLen]);
	Server.jobResult (addr, new thisInformJob, aid, new KV [0]);
    }

    void informJobEnd (uint addr, uint aid, KV [] gets) {
	Server.sendMsg (gets.length, cast (shared (KV)*) gets.ptr);
    }
        
    void informRemote (uint fst, uint scd, ulong [] ids, uint assoc) {
	Server.jobRequest (fst, new thisInformJob, assoc, ids);
	ulong len; shared (KV) * aux;
	Server.waitMsg (len, aux);
	if (aux !is null) {
	    auto kvs = (cast (KV*) aux) [0 .. len];
	    Server.jobRequest (scd, new thisSetJob, assoc, kvs);
	}
    }
    
    void executeReduce (DistGraph!(VD, ED) gp, ref DArray assoc) {
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

    void syncJob (uint addr, uint id) {
	writeln ("Sync recv");
	stdout.flush ();
	Server.jobResult (addr, new thisSyncJob, id);
    }
    
    void syncJobEnd (uint addr, uint id) {
	Server.sendMsg (id);
    }    
    
    auto MapReduceTripletsS (T : DistGraph!(VD, ED)) (T gp) {
	auto result = new DArray;
	// Chaque partie du graphe execute le map
	foreach (it ; Server.connected) {
	    Server.jobRequest (it, new thisMapReduceJob, gp.id, result.id);
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
	    Server.jobRequest (it, new thisSyncJob, 0);
	}

	foreach (it ; Server.connected) {
	    Server.waitMsg!(uint);
	}	
	
	return result;
    }
    
}
