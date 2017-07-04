module assign.skeleton.Init;
import assign.launching;
import std.traits;
import assign.Job;
import std.concurrency;
import assign.data.Array;
import assign.cpu;
import std.stdio;

template Init (alias fun) {

    alias T = ReturnType!fun;

    alias thisJob = Job!(initJob, endJob);

    void init (ulong begin, shared T [] datas) {
	if (datas.length != 0) {
	    foreach (it ; 0 .. datas.length) {
		datas [it] = fun (begin + it);
	    }
	}
    }

    void init (ulong begin, T [] datas) {
	if (datas.length != 0) {
	    foreach (it ; 0 .. datas.length) {
		datas [it] = fun (begin + it);
	    }
	}
    }
    
    void initJob (uint addr, uint id) {
	auto array = DataTable.get!(DistArray!T) (id);
	auto nb = SystemInfo.cpusInfo().length;
	writeln ("Th ", nb);
	
	foreach (it ; 1 .. nb) {
	    if (it != nb - 1) {
		shared b = cast (shared (T[])) array.local [(array.localLength / nb) * it ..
							    (array.localLength / nb) * (it + 1)];
		spawn (&initSlave, thisTid, array.begin + (array.localLength / nb) * it, b);
	    } else {
		shared b = cast (shared (T[])) array.local [(array.localLength / nb) * it ..
							    $];
		spawn (&initSlave, thisTid, array.begin + (array.localLength / nb) * it, b);
	    }
	}

	init (array.begin, array.local [0 .. array.localLength / nb]);
	foreach (it ; 0 .. nb - 1) {
	    Server.waitMsg!bool ();
	}
	
	Server.jobResult!(thisJob) (addr, id);
    }

    void endJob (uint addr, uint id) {
	Server.sendMsg (id);
    }

    void Init (DistArray!T array) {
	foreach (key, value ; array.machineBegins) {
	    if (key != Server.machineId) {
		Server.jobRequest!(thisJob) (key, array.id);
	    }
	}

	auto nb = SystemInfo.cpusInfo().length;
	writeln ("Th ", nb);
	
	foreach (it ; 1 .. nb) {
	    if (it != nb - 1) {
		shared b = cast (shared (T[])) array.local [(array.localLength / nb) * it ..
							    (array.localLength / nb) * (it + 1)];
		spawn (&initSlave, thisTid, array.begin + (array.localLength / nb) * it, b);
	    } else {
		shared b = cast (shared (T[])) array.local [(array.localLength / nb) * it ..
							    $];
		spawn (&initSlave, thisTid, array.begin + (array.localLength / nb) * it, b);
	    }
	}

	init (array.begin, array.local [0 .. array.localLength / nb]);
	foreach (it ; 0 .. nb - 1) {
	    Server.waitMsg!bool ();
	}

	foreach (key, value ; array.machineBegins) {
	    if (key != Server.machineId) {
		Server.waitMsg!(uint);
	    }
	}	
    }

    void initSlave (Tid owner, ulong begin, shared T [] datas) {
	init (begin, datas);
	send (owner, true);
    }


}
