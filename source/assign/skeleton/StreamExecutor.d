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
	
	foreach (node ; stream.tree) {
	    auto tsk = cast (shared (Node)*) &node;	    
	    auto divide = node.task.divide (nb, fed);	    
	    foreach (it ; 0 .. divide [0].length) {
		auto _in = cast (shared (Feeder)*) &divide [0][it];
		auto _out = cast (shared (Feeder)*) &divide [1][it];
		spawn (&onWork, thisTid, tsk, _in, _out);
	    }

	    foreach (it ; 0 .. divide [0].length) {
		receiveOnly!(bool);
	    }
	    
	    fed = node.task.finalize (divide [2][0]);
	}
	return fed;
    }

    static void onWork (Tid owner, shared (Node)* tsk, shared (Feeder)*data, shared (Feeder)* odata) {
	auto i = cast (Feeder) *data;
	auto o = cast (Feeder) *odata;
	auto task = cast (Task) tsk.task;
	task.run (i, o);
	send (owner, true);
    }
        
    mixin Singleton;
}
