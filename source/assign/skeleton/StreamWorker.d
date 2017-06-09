module assign.skeleton.StreamWorker;
import utils.Singleton;
import assign.skeleton.Task;
import assign.skeleton.Stream;
import std.concurrency;
import std.container;
import assign.cpu;
import std.stdio;

class StreamWorkerS {

    struct Worker {
	ulong id;
	shared (Feeder) * ptr;
    }

    /// La table qui contient les différents workers en cours de travail.
    private Worker [Tid][ulong] _workers;

    /// La liste des workers physique (qui vont simuler, les autres).
    private Array!Tid _realWorkers;

    void setWorkers (Tid [] who) {
	this._realWorkers = make!(Array!Tid) (who);
    }
    
    void addWorker (Tid who) {
	this._realWorkers.insertBack (who);
    }    
    
    Worker self (ulong taskId) {
	return this._workers [taskId][thisTid];
    }

    Tid master (ulong taskId) {
	foreach (key, value ; this._workers [taskId]) {
	    if (value.id == 0) return key;
	}
	assert (false, "Aucun maître, probablement aucun workers");
    }
    
    Worker [ulong] others (ulong taskId) {
	Worker [ulong] ret;
	foreach (key, value ; this._workers [taskId]) {	    
	    if (key != thisTid) {
		ret [value.id] = value;
	    }
	}
	return ret;
    }

    Worker [Tid] spawnTask (ulong taskId, ref Feeder [] who) {
	Worker [Tid] current;
	foreach (it ; 0 .. who.length) {
	    current [this._realWorkers [it % $]] = Worker (it, cast (shared (Feeder)*) &who [it]);
	}
	this._workers [taskId] = current;
	return current;
    }    
    
    void endTask (ulong taskId) {
	this._workers.remove (taskId);
    }
    
    void joinAll () {
	foreach (it ; this._realWorkers) {
	    send (it, true);
	    receiveOnly!(bool);
	}
    }
    
    mixin ThreadSafeSingleton;
}

alias StreamWorker = StreamWorkerS.instance;
