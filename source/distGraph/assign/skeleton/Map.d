module distGraph.assign.skeleton.Map;
import distGraph.assign.launching;
import std.traits;
import distGraph.assign.Job;
import std.concurrency;
import distGraph.assign.data.Array;
import distGraph.assign.cpu;
import std.stdio, std.conv, std.typecons;
import dsl._;
import CL = openclD._;

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
	auto array = DataTable.get!(DistArray!T) (id);
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
	    Server.waitMsg!bool ();
	}
	Server.jobResult!(thisJob) (addr, id);
    }

    void endJob (uint addr, uint id) {
	Server.sendMsg (id);
    }
    
    auto Map (DistArray!T array) {
	alias thisJob = Job!(mapJob, endJob);
	foreach (id ; Server.connected) {
	    Server.jobRequest!(thisJob) (id, array.id);	    
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
	    Server.waitMsg!bool ();
	}
	writeln ("FIN");
	foreach (id ; Server.connected) {
	    writeln ("ID :", id);
	    Server.waitMsg!(uint);	    
	}
	writeln ("FIN2");
	return array;	
    }

    void mapSlave (Tid owner, ulong begin, shared T [] datas) {
	map (begin, datas);
	send (owner, true);
    }   
}
