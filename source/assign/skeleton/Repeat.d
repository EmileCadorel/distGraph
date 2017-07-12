module assign.skeleton.Repeat;
import assign.skeleton.Task;

class Repeat(T) : SyncTask {

    private Task _task;

    this () {}
    
    this (Task task) {
	this._task = task;
    }

    override Feeder run (Feeder _in, Feeder _outF = Feeder.empty) {
	auto _out = this._task.output (_in);
	while (_in.length!(T) > 1) {	    
	    _out = this._task.run (_in, _out);
	    _in = _out;
	}
	return _out;
    }

    override Feeder distJob (Feeder) {
	assert (false, "TODO");
    }
    
    override Feeder finalize (Feeder [] _in) {
	auto total = 0;
	foreach (it ; _in) {
	    total += it.length!(T);
	}
	auto res = alloc!(T) (total);
	ulong i = 0;
	
	foreach (it ; _in) {
	    res[i] = it.get!(T[])[0];
	    i++;	    
	}

	auto fed = run (Feeder (res));
	return fed;
    }

    override Feeder output (Feeder) {
	return Feeder (alloc!(T)(1));
    }
    
    override Feeder [] divide (ulong nb, Feeder _in) {
	Feeder [] ret = alloc!(Feeder) (nb);	
	auto datas = _in.get!(T[]);
	
	foreach (it ; 0 .. nb) {
	    if (it < nb - 1) {
		ret [it] = Feeder (datas [(datas.length / nb * it) .. (datas.length / nb ) * (it + 1)]);
	    } else {
		ret [it] = Feeder (datas [(datas.length / nb) * it .. $]);
	    }
	}
	return ret;
    }
    
    override Task clone () {
	auto ret = new Repeat!T (this._task.clone);
	return ret;
    }
    
};
