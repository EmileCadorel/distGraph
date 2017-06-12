module assign.skeleton.StreamExecutor;
import assign.skeleton.Stream;
import utils.Singleton;
import assign.cpu;
import std.concurrency;
import std.stdio;

class StreamExecutor {
    
    Feeder execute (T) (Stream stream, T data) {
	auto nb = SystemInfo.cpusInfo.length;
	auto fed = Feeder (data);
	auto spawned = new Tid [nb];
	auto divided = false;
	ulong currentNb = 0;
	
	foreach (it ; 0 .. nb) {
	    spawned [it] = spawn (&onWork, thisTid);
	}	
	
	foreach (node ; stream.tree) {
	    if (!divided) {
		currentNb = sendDivision (node.task, spawned, fed);
		divided = true;
	    }
	    
	    if (auto task = cast (SyncTask) node.task) {
		foreach (it ; 0 .. currentNb) {
		    send (spawned [it], cast (shared (SyncTask)*) &task, true);
		}
		
		Feeder [] res = new Feeder [currentNb];
		foreach (it ; 0 .. currentNb) {
		    res[it] = cast (Feeder) *receiveOnly!(shared (Feeder)*);		    
		}
		
		fed = task.finalize (res);
		divided = false;
	    } else {
		foreach (it; 0 .. currentNb) {
		    send (spawned [it], cast (shared (Task)*) &node.task);
		}		
	    }
	}

	Feeder res;
	foreach (it ; 0 .. currentNb) {
	    send (spawned [it], true);
	    if (it == 0) res = cast(Feeder)*receiveOnly!(shared (Feeder)*);
	    else 
		res.concat (cast(Feeder)*receiveOnly!(shared (Feeder)*));
	    
	}
	
	foreach (it; currentNb .. nb) {
	    send (spawned [it], false);
	}
	
	return res;
    }
    
    ulong sendDivision (Task task, Tid [] spawned, Feeder data) {
	auto divide = task.divide (spawned.length, data);
	foreach (it ; 0 .. divide.length) {
	    send (spawned [it], cast (shared (Feeder)*) &divide [it]);
	}
	return divide.length;
    }

    static void onWork (Tid owner) {
	bool end = false;
	Feeder current;
	while (!end) {
	    receive (
		(shared (Task)* tsk) { // Async
		    auto task = (cast (Task) *tsk);
		    current = task.run (current);		    
		},
		(shared (SyncTask)*tsk, bool) { // Sync
		    auto task = (cast (Task) *tsk);
		    current = task.run (current);
		    send (owner, cast (shared (Feeder)*) &current);
		},
		(shared (Feeder)* _in) {
		    current = cast (Feeder) *_in;
		},
		(bool ret) {
		    end = true;
		    if (ret)
			send (owner, cast (shared(Feeder)*) &current);
		}
	    );
	}
    }
    
    // static void onWork (Tid owner, shared (Node)* tsk, shared (Feeder)*data, shared (Feeder)* odata) {
    // 	auto i = cast (Feeder) *data;
    // 	auto o = cast (Feeder) *odata;
    // 	auto task = cast (Task) tsk.task;
    // 	task.run (i, o);
    // 	send (owner, true);
    // }
        
    mixin Singleton;
}
