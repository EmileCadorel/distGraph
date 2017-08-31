module distGraph.assign.skeleton.StreamExecutor;
import distGraph.assign.skeleton.Stream;
import distGraph.assign.data.Data;
import distGraph.assign.launching;
import distGraph.utils.Singleton;
import distGraph.assign.cpu;
import std.concurrency;
import std.stdio;

class StreamExecutor {
    
    DistData execute (T) (Stream stream, T data) {
	auto nb = SystemInfo.cpusInfo.length;
	auto fed = Feeder (data);
	auto spawned = new Tid [nb];
	auto divided = false;
	uint currentNb = 0, currentId = 0;
	
	foreach (it ; 0 .. nb) {
	    spawned [it] = spawn (&onWork, thisTid);
	}	
	
	foreach (node ; stream.tree) {
	    if (!divided) {
		currentNb = sendDivision (node.task, spawned, currentId, fed);
		divided = true;
	    }
	    
	    if (auto task = cast (SyncTask) node.task) {
		foreach (it ; 0 .. currentNb) {
		    send (spawned [it], cast (shared (SyncTask)*) &task, currentId);
		}
		
		Feeder [] res = new Feeder [currentNb];
		foreach (it ; 0 .. currentNb) {
		    res[it] = cast (Feeder) *receiveOnly!(shared (Feeder)*);   	   
		}
		
		fed = task.finalize (res);
		divided = false;
	    } else {
		foreach (it; 0 .. currentNb) {
		    send (spawned [it], cast (shared (Task)*) &node.task, currentId);
		}		
	    }
	}

	foreach (it ; 0 .. nb)
	    send (spawned [it], false);

	foreach (it ; 0 .. nb)
	    receiveOnly!bool;
	
	return DataTable [currentId];
    }

    
    uint sendDivision (Task task, Tid [] spawned, ref uint id, Feeder _in) {	
	/*auto data = task.distribute (_in);
	writeln (data.id);
	id = data.id;
	auto divide = task.divide (spawned.length, Feeder (data.localData));
	foreach (it ; 0 .. divide.length) {
	    send (spawned [it], id, cast (shared (Feeder)*) &divide [it]);
	}
	return cast (uint) divide.length;*/
	assert (false);
    }

    static void onWork (Tid owner) {
	bool end = false;
	Feeder [uint] current;
	while (!end) {
	    receive (
		(shared (Task)* tsk, uint id) { // Async
		    auto task = (cast (Task) *tsk);
		    current [id] = task.run (current [id]);
		},
		(shared (SyncTask)*tsk, uint id) { // Sync
		    auto task = (cast (Task) *tsk);
		    current [id] = task.run (current [id]);
		    send (owner, cast (shared (Feeder)*) &current [id]);
		},
		(uint id, shared (Feeder)* _in) {
		    current [id] = cast (Feeder) *_in;
		},
		(bool) {
		    send (owner, true);
		    end = true;
		}
	    );
	}
    }
            
    mixin Singleton;
}
