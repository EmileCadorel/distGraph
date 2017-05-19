module assign.skeleton.Map;
import assign.launching;
import std.traits;
import assign.Job;
import std.concurrency;
import assign.data.Array;
import assign.cpu;
import std.stdio, std.conv, std.typecons;

template Map (alias dg) {

    alias T = ReturnType!dg;
    
    alias thisJob = Job!(mapJob, endJob);
    
    void map (ulong begin, shared T [] datas) {
	auto result = 0;
	for (ulong i = 0 ; i < datas.length ; i++) {
	    datas [i] = dg (i + begin, datas [i]);
	}
    }

    void mapJob (uint addr, uint id) {
	auto array = ArrayTable.get!(DistArray!T) (id);
	auto nb = SystemInfo.cpusInfo ().length;
	writeln ("Th ", nb);
	foreach (it ; 1 .. nb) {
	    if (it != nb - 1) {
		shared b = cast (shared (T[])) array.local [(array.localLength / nb) * it ..
							    (array.localLength / nb) * (it + 1)];
		spawn (&mapSlave, thisTid, array.begin + (array.localLength / nb) * it, b);
	    } else {
		shared b = cast (shared (T[])) array.local [(array.localLength / nb) * it ..
							    $];
		spawn (&mapSlave, thisTid, array.begin + (array.localLength / nb) * it, b);
	    }
	}

	map (array.begin, cast (shared T[]) (array.local [0 .. array.localLength / nb]));
	foreach (it ; 0 .. nb - 1) {
	    receiveOnly!bool ();
	}
	Server.jobResult (addr, new thisJob, id);
    }

    void endJob (uint addr, uint id) {
	Server.sendMsg (id);
    }
    
    auto Map (DistArray!T array) {
	alias thisJob = Job!(mapJob, endJob);
	foreach (key, value ; array.machineBegins) {
	    if (key != Server.machineId) {
		Server.jobRequest (key, new thisJob (), array.id);
	    }
	}

	auto nb = SystemInfo.cpusInfo ().length;
	foreach (it ; 1 .. nb) {
	    if (it != nb - 1) {
		shared b = cast (shared (T[])) array.local [(array.localLength / nb) * it ..
							    (array.localLength / nb) * (it + 1)];
		spawn (&mapSlave, thisTid, array.begin + (array.localLength / nb) * it, b);
	    } else {
		shared b = cast (shared (T[])) array.local [(array.localLength / nb) * it ..
							    $];
		spawn (&mapSlave, thisTid, array.begin + (array.localLength / nb) * it, b);
	    }
	}

	map (array.begin, cast (shared T[]) (array.local [0 .. array.localLength / nb]));
	
	foreach (it ; 0 .. nb - 1) {
	    receiveOnly!bool ();
	}

	foreach (key, value ; array.machineBegins) {
	    if (key != Server.machineId) {
		Server.waitMsg!(uint);
	    }
	}
	
	return array;
    }

    void mapSlave (Tid owner, ulong begin, shared T [] datas) {
	map (begin, datas);
	send (owner, true);
    }   
}
