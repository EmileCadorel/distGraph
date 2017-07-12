module assign.skeleton.Init;
import assign.launching;
import std.traits;
import assign.Job;
import std.concurrency;
import assign.data.Array;
import assign.cpu;
import std.stdio, core.thread;

template Init (alias fun) {
    auto Init (T) (DistArray!T data) {
	return InitImpl!(T, fun) (data);
    }
}


template InitImpl (T, alias fun) {

    alias thisJob = Job!(initJob, endJob);

    static class InitThread : Thread {
	private T[] _datas;
	private ulong _begin;

	this (ulong begin, T[] datas) {
	    super (&this.run);
	    this._begin = begin;
	    this._datas = datas;
	}

	void run () {
	    if (this._datas.length != 0) {
		foreach (it ; 0 .. this._datas.length) {
		    this._datas [it] = fun (this._begin + it);
		}
	    }
	}
    }

    
    static void init (ulong begin, T [] datas) {
	if (datas.length != 0) {
	    foreach (it ; 0 .. datas.length) {
		datas [it] = fun (begin + it);
	    }
	}
    }
    
    static void initJob (uint addr, uint id) {
	auto array = DataTable.get!(DistArray!T) (id);
	auto nb = SystemInfo.cpusInfo().length;
	auto res = new Thread [nb - 1];
	
	foreach (it ; 1 .. nb) {
	    if (it != nb - 1) {
		auto b = array.local [(array.localLength / nb) * it ..
				      (array.localLength / nb) * (it + 1)];
		res [it - 1] = new InitThread (array.begin + (array.localLength / nb) * it, b).start ();
	    } else {
		auto b = array.local [(array.localLength / nb) * it .. $];
		res [it - 1] = new InitThread (array.begin + (array.localLength / nb) * it, b).start ();
	    }
	}

	init (array.begin, array.local [0 .. array.localLength / nb]);
	
	foreach (it ; res) {
	    it.join ();
	}
	
	Server.jobResult!(thisJob) (addr, id);
    }

    static void endJob (uint addr, uint id) {
	Server.sendMsg (id);
    }

    auto InitImpl (DistArray!T array) {
	foreach (id; Server.connected) {
	    Server.jobRequest!(thisJob) (id, array.id);	    
	}

	auto nb = SystemInfo.cpusInfo().length;
	auto res = new Thread [nb - 1];
	
	foreach (it ; 1 .. nb) {
	    if (it != nb - 1) {
		auto b = array.local [(array.localLength / nb) * it ..
				      (array.localLength / nb) * (it + 1)];
		res [it - 1] = new InitThread (array.begin + (array.localLength / nb) * it, b).start ();
	    } else {
		auto b = array.local [(array.localLength / nb) * it .. $];
		res [it - 1] = new InitThread (array.begin + (array.localLength / nb) * it, b).start ();
	    }
	}


	init (array.begin, array.local [0 .. array.localLength / nb]);
	
	foreach (it ; res) {
	    it.join ();
	}
	
	foreach (id ; Server.connected) {
	    Server.waitMsg!(uint);	
	}
	
	return array;
    }

}
