module assign.skeleton.Reduce;
import assign.launching;
import std.traits;
import std.stdio;
import assign.Job;
import std.concurrency;
import assign.cpu;
import assign.data.Array;
import core.thread;

template Reduce (alias fun) {

    auto Reduce (T) (DistArray!T data) {
	return ReduceImpl!(T, fun) (data);
    }
    
}

template ReduceImpl (T, alias fun) {
    
    alias thisJob = Job!(reduceJob, answerJob);

    static class ReduceThread : Thread {
	private T[] datas;
	private T _res;
	
	this (T[] datas) {
	    super (&this.run);
	    this.datas = datas;
	}
	
	void run () {
	    ulong anc = datas.length;
	    ulong nb = datas.length / 2;
	    auto padd = 1;
	    while (padd < anc) {
		auto it = 0;
		for (it = 0; (it + padd) < (anc) ; it += (2*padd)) {
		    datas [it] = fun (datas [it], datas [it + padd]);
		}
		
		if (it < anc && (it - (2 * padd)) >= 0) {
		    datas [it - (2 * padd)] = fun (datas [it - (2 * padd)], datas [it]);
		    anc = it;
		}
		
		padd *= 2;
	    }
	    
	    this._res = datas [0];    
	}

	T res () {
	    return this._res;
	}
    }

    static T reduceArray () (T [] datas) {
	ulong anc = datas.length;
	ulong nb = datas.length / 2;
	auto padd = 1;
	while (padd < anc) {
	    auto it = 0;
	    for (it = 0; (it + padd) < (anc) ; it += (2*padd)) {
		datas [it] = fun (datas [it], datas [it + padd]);
	    }
	
	    if (it < anc && (it - (2 * padd)) >= 0) {
		datas [it - (2 * padd)] = fun (datas [it - (2 * padd)], datas [it]);
		anc = it;
	    }
	    
	    padd *= 2;
	}
    
	return datas [0];    
    }
    
    static void reduceJob (uint addr, uint id) {
	auto array = DataTable.get!(DistArray!T) (id);
	auto nb = SystemInfo.nbThreadsPerCpu ();
	auto res = new Thread [nb - 1];
	
	foreach (it ; 1 .. nb) {
	    if (it != nb - 1) {
		auto b = array.local [(array.localLength / nb) * (it) .. (array.localLength / nb) * (it + 1)];
		res [it - 1] = new ReduceThread (b).start ();
	    } else {
		auto b = array.local [(array.localLength / nb) * (it) .. $];
		res [it - 1] = new ReduceThread (b).start ();
	    }
	}
	
	T soluce = reduceArray (array.local [0 .. (array.localLength / nb)]);
	
	foreach (it ; res) {
	    it.join ();
	    soluce = fun (soluce, (cast (ReduceThread) it).res);
	}
       	Server.jobResult!(thisJob) (addr, id, soluce);
    }

    static void answerJob (uint addr, uint jbId, T res) {
	Server.sendMsg (res);
    }
    
    T ReduceImpl (DistArray!T array) {
	foreach (id ; Server.connected) {
	    Server.jobRequest!(thisJob) (id, array.id);	    
	}
	
	auto nb = SystemInfo.nbThreadsPerCpu ();
	auto res = new Thread [nb - 1];
	
	foreach (it ; 1 .. nb) {
	    if (it != nb - 1) {
		auto b = array.local [(array.localLength / nb) * (it) .. (array.localLength / nb) * (it + 1)];
		res [it - 1] = new ReduceThread (b).start ();
	    } else {
		auto b = array.local [(array.localLength / nb) * (it) .. $];
		res [it - 1] = new ReduceThread (b).start ();
	    }
	}
	
	T soluce = reduceArray (array.local [0 .. (array.localLength / nb)]);	

	foreach (it ; res) {
	    it.join ();
	    soluce = fun ((cast (ReduceThread) it).res, soluce);
	}
	
	foreach (id ; Server.connected) {
	    auto t = Server.waitMsg!T ();
	    soluce = fun (soluce, t);
	}
	
	return soluce;
    }
  
}
