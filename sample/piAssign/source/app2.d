import assign.skeleton.Stream;
import std.stdio;
import std.traits;
import std.datetime;

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

    override void reset () {
	this._nbData = 0;
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

    override void reset () {
	this._get = false;
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
	
	auto res = new T [data.length / this._task.arity
			  + data.length % this._task.arity];

	uint i = 0;
	for (; (i + this._task.arity) <= data.length; i += this._task.arity) {
	    this._task.reset;
	    for (uint j = 0; j < this._task.arity; j++) {
		this._task.feed (Feeder (data [i + j]));
	    }
	    res [i / this._task.arity] = this._task.run ().get!T;
	}
	
	for (uint j = 0; (j + i) < data.length; j ++) {
	    res [j + (i / this._task.arity)] = data [i + j];
	}
	
	return Feeder (res);
    }    
    
    override uint arity () {
	return this._task.arity;
    }

    override void reset () {}
           
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
	ulong data;
	if (this.next.isTask) {
	    data = this.next.run (this._data).get!ulong;
	} else {
	    data = this._data.get!ulong;
	}
	
	auto res = new T [data / this._task.arity
			  + data % this._task.arity];

	uint i = 0;
	for (; (i + this._task.arity) <= data; i += this._task.arity) {
	    this._task.reset;
	    for (ulong j = 0; j < this._task.arity; j++) {
		auto aux = i + j;
		this._task.feed (Feeder (aux));
	    }
	    res [i / this._task.arity] = this._task.run ().get!T;
	}

	return Feeder (res);
    }    
    
    override uint arity () {
	return this._task.arity;
    }

    override void reset () {
	this._get = false;
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

    override Feeder run () {
	T [] data;
	if (this.next.isTask) {
	    data = this.next.run (this._data).get!(T[]);
	} else {
	    data = this._data.get!(T[]);
	}
	
	while (data.length > 1) {	    
	    this._task.feed (Feeder (data));
	    data = this._task.run.get!(T[]);
	}
	return Feeder (data);
    }
    
    override uint arity () {
	return this._task.arity;
    }

    override void reset () {
	this._get = false;
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

