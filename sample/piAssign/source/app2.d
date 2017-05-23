import assign.skeleton.Stream;
import std.stdio;
import std.traits;
import std.datetime;
import std.concurrency;
import std.typecons;

class Elem (alias fun) : Task {

    static assert (checkFun !(fun));
    enum __ARITY__ = ParameterTypeTuple!(fun).length;
    alias T = ParameterTypeTuple!(fun) [0];
    alias TUPLE = Tuple!(ParameterTypeTuple!(fun));
    
    static bool checkFun (alias fun) () {
	static if (is (ReturnType!fun : void)) return false;
	alias t1 = ParameterTypeTuple!(fun);	
	static if (t1.length == 1) return true;
	else {
	    foreach (i, it ; t1) {
		static if (!is (t1 [i] : t1 [0]))
		    return false;
	    }
	    return true;
	}
    }    
    
    private Feeder _data;
    private T [__ARITY__] _aux;

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
	for (; (i + __ARITY__) <= data.length; i += __ARITY__) {
	    for (uint j = 0; j < __ARITY__; j++) {
		this._aux [j] = data [i + j];
	    }
	    
	    TUPLE tu = this._aux;
	    data [i / __ARITY__] = fun (tu.expand);
	}
	
	for (uint j = 0; (j + i) < data.length; j ++) {
	    data [j + (i / __ARITY__)] = data [i + j];
	}
	
	return Feeder (data [0 .. (data.length / __ARITY__
				   + data.length % __ARITY__)]);
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
	return __ARITY__;
    }

    override void reset () {}

    override Task clone () {
	auto ret = new Elem!fun ();
	ret.next = this.next;
	return ret;
    }

    
};
       		  
class IndexedElem (alias fun) : Task {

    static assert (checkFun !(fun));
    enum __ARITY__ = ParameterTypeTuple!(fun).length;
    alias T = ReturnType!fun;
    
    static bool checkFun (alias fun) () {
	static if (is (ReturnType!fun : void)) return false;
	alias t1 = ParameterTypeTuple!(fun);	
	static if (t1.length == 1 && is (t1 [0] : ulong)) return true;
	else return false;
    }    
    
    private Feeder _data;
    private bool _get = false;

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

       	auto res = new T [len];

	uint i = 0;
	for (; (i + 1) <= len; i += 1) {
	    res [i] = fun (i + begin);
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
	return 1;
    }

    override void reset () {
	this._get = false;
    }

    override Task clone () {
	auto ret = new IndexedElem!fun;
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
	    new Elem!(fun) 	    
	);
    }
}

template Map (alias fun) {
    alias T = ReturnType!fun;

    auto Map () {
	return new Elem!(fun);	    
    }
}

template Generate (alias fun) {
    alias T = ReturnType!fun;

    auto Generate () {
	return new IndexedElem!fun;	
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
	), Map!(
	    (double a) => 4. * a
	)
    );
        
    auto res = stream.run (cast (ulong) n).get!(double[]);
    writefln ("%s %s", res, Clock.currTime - begin);
}

