import assign.skeleton.Stream;
import std.stdio;
import std.traits;
import std.datetime;
import std.concurrency;

class ReduceOp (alias fun) : Task {

    alias T = ReturnType!fun;

    private T [2] _data;
    private ulong _nbData = 0;
    
    override bool full () {
	return this._nbData == 2;
    }

    override Feeder run () {
	auto res = fun (this._data [0], this._data [1]);
	return Feeder (res);
    }

    override uint arity () {
	return 2;
    }
    
    override void feed (Feeder data) {
	this._data [this._nbData] = data.get!T;
	this._nbData ++;
    }

    override Feeder[] divide (ulong nb, Feeder fd) {
	assert (false);
    }

    override void reset () {
	this._nbData = 0;
    }
    
    override Task clone () {
	auto ret = new ReduceOp!fun ();
	ret.next = this.next;
	return ret;
    }

};

class MapOp (alias fun) : Task {

    alias T = ReturnType!fun;
    alias U = ParameterTypeTuple!(fun) [0];

    private U _data;
    private bool _get = false;
    
    override bool full () {
	return this._get;
    }

    override void feed (Feeder data) {
	this._data = data.get!(U);
	this._get = true;
    }

    override uint arity () {
	return 1;
    }

    override Feeder run () {
	return Feeder (fun (this._data));
    }

    override Feeder[] divide (ulong nb, Feeder fd) {
	assert (false);
    }

    override void reset () {
	this._get = false;
    }

    override Task clone () {
	auto ret = new MapOp!fun ();
	ret.next = this.next;
	return ret;
    }

    
}
			  
class Elem (T) : Task {

    private Feeder _data;
    private Task _task;

    this (Task task) {
	this._task = task;
    }

    override bool full () {
	return true;
    }

    override void feed (Feeder data) {
	this._data = data;
    }
    
    override Feeder run () {
	T [] data;
	if (this.next.isTask) {
	    data = this.next.run (this._data).get!(T[]);
	} else {
	    data = this._data.get!(T[]);
	}
	
	uint i = 0;
	for (; (i + this._task.arity) <= data.length; i += this._task.arity) {
	    this._task.reset;
	    for (uint j = 0; j < this._task.arity; j++) {
		this._task.feed (Feeder (data [i + j]));
	    }
	    data [i / this._task.arity] = this._task.run ().get!T;
	}
	
	for (uint j = 0; (j + i) < data.length; j ++) {
	    data [j + (i / this._task.arity)] = data [i + j];
	}
	
	return Feeder (data [0 .. (data.length / this._task.arity
				   + data.length % this._task.arity)]);
    }    

    override Feeder [] divide (ulong nb, Feeder data) {
	auto ret = new Feeder [nb];
	auto datas = data.get!(T[]);
	foreach (it ; 0 .. nb) {
	    if (it < nb - 1)
		ret [nb] = Feeder (datas [(datas.length / nb * it) .. (datas.length / nb ) * (it + 1)]);
	    else
		ret [nb] = Feeder (datas [(datas.length / nb) * it .. $]);
	}
	return ret;
    }
    
    override uint arity () {
	return this._task.arity;
    }

    override void reset () {}

    override Task clone () {
	auto ret = new Elem!T (this._task.clone);
	ret.next = this.next;
	return ret;
    }

    
};
       		  
class IndexedElem (T) : Task {

    private Feeder _data;
    private bool _get = false;
    private Task _task;

    this (Task task) {
	this._task = task;
    }

    override bool full () {
	return this._get;
    }

    override void feed (Feeder data) {
	this._data = data;
	this._get = true;
    }
    
    override Feeder run () {	
	ulong begin, len;
	if (this.next.isTask) {
	    auto data = this.next.run (this._data);
	    if (data.isArray) {
		begin = data.get! (ulong[]) [0];
		len = data.get! (ulong[]) [1];
	    } else {
		len = data.get!ulong;
	    }
	} else {
	    if (this._data.isArray) {
		begin = this._data.get! (ulong[]) [0];
		len = this._data.get! (ulong[]) [1];
	    } else {
		len = this._data.get!ulong;
	    }
	}

       	auto res = new T [len / this._task.arity
			  + len % this._task.arity];

	uint i = 0;
	for (; (i + this._task.arity) <= len; i += this._task.arity) {
	    this._task.reset;
	    for (ulong j = 0; j < this._task.arity; j++) {
		this._task.feed (Feeder (i + j + begin));
	    }
	    res [i / this._task.arity] = this._task.run ().get!T;
	}

	return Feeder (res);
    }    

    override Feeder [] divide (ulong nb, Feeder data) {
	Feeder [] ret = new Feeder [nb];
	auto len = data.get!ulong;
	
	foreach (it ; 0 .. nb) {
	    if (it < nb - 1)
		ret [it] = Feeder ([len / nb * it, len / nb * (it + 1)]);
	    else
		ret [it] = Feeder ([len / nb * it, len - (len / nb * it)]);
	}       
	
	return ret;
    }
    
    override uint arity () {
	return this._task.arity;
    }

    override void reset () {
	this._get = false;
    }

    override Task clone () {
	auto ret = new IndexedElem!T (this._task.clone);
	ret.next = this.next;
	return ret;
    }
    
};

class Repeat(T) : Task {

    private Feeder _data;
    private bool _get = false;
    private Task _task;

    this (Task task) {
	this._task = task;
    }

    override bool full () {
	return this._get;
    }

    override void feed (Feeder data) {
	this._data = data;
	this._get = true;
    }
    
    private static void spawned (Tid owner, shared Feeder sfed, shared Feeder srep, shared Task stask) {
	auto fed = (cast (Feeder) sfed).clone ();
	auto rep = (cast (Feeder) srep).clone ();
	auto task = (cast (Task) stask).clone ();

	auto data = rep.run (fed).get !(T[]);
	while (data.length > 1) {
	    task.feed (Feeder (data));
	    data = task.run.get!(T[]);
	}
	send (owner, data [0]);
    }

    override Feeder run () {
	T [] data;
	if (this.next.isTask) {
	    auto nb = 2;
	    auto div = this.next.task.divide (nb, this._data);
	    foreach (it ; 1 .. nb) {
		spawn (&spawned, thisTid,
		       cast (shared (Feeder)) div [it],
		       cast (shared (Feeder)) this.next,
		       cast (shared (Task)) this._task);
	    }

	    data = this.next.run (div [0]).get!(T[]);
	    
	    while (data.length > 1) {	    
		this._task.feed (Feeder (data));
		data = this._task.run.get!(T[]);
	    }

	    foreach (it ; 1 .. nb) {
		auto res = receiveOnly!(T);
		data ~= [res];
	    }

	    while (data.length > 1) {	    
		this._task.feed (Feeder (data));
		data = this._task.run.get!(T[]);
	    }
	    
	    return Feeder (data);
	} else {
	    data = this._data.get!(T[]);
	
	
	    while (data.length > 1) {	    
		this._task.feed (Feeder (data));
		data = this._task.run.get!(T[]);
	    }
	    return Feeder (data);
	}
    }

    override Feeder [] divide (ulong nb, Feeder data) {
	auto ret = new Feeder [nb];
	auto datas = data.get!(T[]);
	foreach (it ; 0 .. nb) {
	    if (it < nb - 1)
		ret [nb] = Feeder (datas [(datas.length / nb * it) .. (datas.length / nb ) * (it + 1)]);
	    else
		ret [nb] = Feeder (datas [(datas.length / nb) * it .. $]);
	}
	return ret;
    }
    
    override uint arity () {
	return this._task.arity;
    }

    override void reset () {
	this._get = false;
    }

    override Task clone () {
	auto ret = new Repeat!T (this._task.clone);
	ret.next = this.next.clone ();
	return ret;
    }
    
};

template Reduce (alias fun) {

    alias T = ReturnType!fun;

    auto Reduce () {
	return new Repeat!T (
	    new Elem!(T) (
		new ReduceOp!(fun)
	    )
	);
    }
}

template Map (alias fun) {
    alias T = ReturnType!fun;

    auto Map () {
	return 
	    new Elem!(T) (
		new MapOp!(fun)
	    );	
    }
}

template Generate (alias fun) {
    alias T = ReturnType!fun;

    auto Generate () {
	return new IndexedElem!T (
	    new MapOp!(fun)
	);
    }
    
}

void main2 () {    
    auto stream = new Stream;
    enum n = 1_000_000;
    auto begin = Clock.currTime;
    stream.compose (	
	Generate! (
	    (ulong i) {
		return (1.0 / n) / ( 1.0 + (( i - 0.5 ) * (1.0 / n)) * (( i - 0.5 ) * (1.0 / n)));
	    }
	),
	Reduce !(
	    (double a, double b) => a + b
	),
	Map !(
	    (double a) => 4. * a
	)
    );
        
    auto res = stream.run (cast (ulong) n).get!(double[]);
    writefln ("%s %s", res, Clock.currTime - begin);
}

