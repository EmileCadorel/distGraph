module assign.skeleton.Reduce;
import assign.launching;
import std.traits;
import std.stdio;
import assign.Job;
import std.concurrency;
import assign.cpu;
import assign.data.Array;

template Reduce(alias fun) {
    
    alias T = ReturnType!fun;        

    alias thisJob = Job!(reduceJob, answerJob);
               
    T reduceArray () (T [] datas) {
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

    T reduceArray () (shared T [] datas) {
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
    
    void reduceJob (uint addr, uint id) {
	auto array = ArrayTable.get!(DistArray!T) (id);
	auto nb = SystemInfo.nbThreadsPerCpu ();

	foreach (it ; 1 .. nb) {
	    if (it != nb - 1) {
		shared b = cast (shared(T[])) array.local [(array.localLength / nb) * (it) .. (array.localLength / nb) * (it + 1)];
		spawn (&reduceSlave, thisTid, b);
	    } else {
		shared b = cast (shared(T[])) array.local [(array.localLength / nb) * (it) .. $];
		spawn (&reduceSlave, thisTid, b);
	    }
	}
	
	T soluce = reduceArray (array.local [0 .. (array.localLength / nb)]);
	
	foreach (it ; 0 .. nb - 1) {
	    T res = receiveOnly!T ();
	    soluce = fun (soluce, res);
	}

       	Server.jobResult (addr, new thisJob(), id, soluce);
    }

    void answerJob (uint addr, uint jbId, T res) {
	Server.sendMsg (res);
    }
    
    T Reduce (DistArray!T array) {
	foreach (key, value ; array.machineBegins) {
	    if (key != Server.machineId) {
		Server.jobRequest (key, new thisJob (), array.id);
	    }
	}
	
	auto nb = SystemInfo.nbThreadsPerCpu ();
	foreach (it ; 1 .. nb) {
	    if (it != nb - 1) {
		shared b = cast (shared(T[])) array.local [(array.localLength / nb) * (it) .. (array.localLength / nb) * (it + 1)];
		spawn (&reduceSlave, thisTid, b);
	    } else {
		shared b = cast (shared(T[])) array.local [(array.localLength / nb) * (it) .. $];
		spawn (&reduceSlave, thisTid, b);
	    }
	}

	T soluce = reduceArray (array.local [0 .. (array.localLength / nb)]);	

	foreach (it ; 0 .. nb - 1) {
	    T res = receiveOnly!T ();
	    soluce = fun (res, soluce);
	}
	
	foreach (key, value ; array.machineBegins) {
	    if (key != Server.machineId) {
		soluce = fun (soluce, Server.waitMsg!T ());
	    }
	}
	
	return soluce;
    }

    void reduceSlave (Tid owner, shared T [] datas) {
	send (owner, reduceArray (datas));
    }
    
   
}
