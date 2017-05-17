import assign.launching;
import std.traits;
import std.stdio;
import assign.Job;
import std.concurrency;

template Reduce(alias fun) {
    
    alias T = ReturnType!fun;        

    alias thisJob = Job!(reduceJob, answerJob);

    __gshared bool soluced = false;
    
    __gshared T soluce;
    
    T reduceArray (T [] datas) {
	if (datas.length == 0) return T.init;
	T fst = datas [0];
	foreach (it ; 1 .. datas.length) {
	    fst = fun (fst, datas [it]);
	}
	return fst;
    }

    T reduceArray (shared T [] datas) {
	if (datas.length == 0) return T.init;
	T fst = datas [0];
	foreach (it ; 1 .. datas.length) {
	    fst = fun (fst, datas [it]);
	}
	return fst;
    }    

    void reduceJob (uint addr, uint jbId, T [] data, uint nb) {
	foreach (it ; 1 .. nb) {
	    shared b = cast (shared(T[])) data [(data.length / nb) * (it) .. (data.length / nb) * (it + 1)];
	    spawn (&reduceSlave, thisTid, b);
	}
	
	T soluce = reduceArray (data [0 .. (data.length / nb)]);	
	foreach (it ; 0 .. nb - 1) {
	    T res = receiveOnly!T ();
	    soluce = fun (soluce, res);
	}
	
	Server.jobResult (addr, new thisJob(), jbId, soluce);
    }

    void answerJob (uint addr, uint jbId, T res) {
	writefln ("Res (%d, %d)", jbId, res);
	Server.sendMsg (res);
    }
    
    T Reduce (T [] data, uint nb) {
	uint nbMac = (cast(uint) Server.connected.length + 1);
	foreach (it ; 0 .. nbMac - 1) {
	    if (it != nbMac - 2) 
		Server.jobRequest (Server.connected [it], new thisJob (), 0U, data [(data.length / nbMac) * (it + 1) ..
										    (data.length / nbMac) * (it + 2)],
				   nb
		);
	    else
		Server.jobRequest (Server.connected [it], new thisJob (), 0U,
				   data [(data.length / nbMac) * (it + 1) .. $],
				   nb
		);
	}
	
	if (nbMac != 0)
	    data = data [0 .. (data.length / nbMac)];

	foreach (it ; 1 .. nb) {
	    if (it != nb - 1) {
		shared b = cast (shared(T[])) data [(data.length / nb) * (it) .. (data.length / nb) * (it + 1)];
		spawn (&reduceSlave, thisTid, b);
	    } else {
		shared b = cast (shared(T[])) data [(data.length / nb) * (it) .. $];
		spawn (&reduceSlave, thisTid, b);
	    }
	}
	
	T soluce = reduceArray (data [0 .. (data.length / nb)]);	
	
	foreach (it ; 0 .. nb - 1) {
	    T res = receiveOnly!T ();
	    soluce = fun (res, soluce);
	}
	soluced = true;
	
	foreach (it ; 0 .. Server.connected.length) {
	    soluce = fun (soluce, Server.waitMsg!T ());
	}
	
	return soluce;
    }

    void reduceSlave (Tid owner, shared T [] datas) {
	send (owner, reduceArray (datas));
    }
    
   
}
