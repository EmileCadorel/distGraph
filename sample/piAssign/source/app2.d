import assign.skeleton.Stream;
import std.stdio;
import std.traits;
import std.datetime;
import std.concurrency;
import std.typecons;

class Elem (alias fun) : Task {
    mixin NominateTask;

    enum __ARITY__ = ParameterTypeTuple!(fun).length;
    alias T = ParameterTypeTuple!(fun) [0];
    alias TUPLE = Tuple!(ParameterTypeTuple!(fun));

    override Feeder run (Feeder _data) {
	T [__ARITY__] aux;
	T [] data = _data.get!(T[]);		
	uint i = 0;
	for (; (i + __ARITY__) <= data.length; i += __ARITY__) {
	    for (uint j = 0; j < __ARITY__; j++) {
		aux [j] = data [i + j];
	    }
	    
	    TUPLE tu = aux;
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

    override Feeder merge (Feeder [] elem) {
	auto res = elem [0];
	foreach (it ; 1 .. elem.length)
	    res = Feeder (res.get!(T[]) ~ elem [it].get!(T[]));
	
	return res;
    }
    
    override uint arity () {
	return __ARITY__;
    }

    override Task clone () {
	auto ret = new Elem!fun ();
	return ret;
    }

    
};
       		  
class IndexedElem (alias fun) : Task {
    mixin NominateTask;

    
    enum __ARITY__ = ParameterTypeTuple!(fun).length;
    alias T = ReturnType!fun;
            
    override Feeder run (Feeder data) {	
	ulong begin, len;

	if (data.isArray) {
	    begin = data.get! (ulong[]) [0];
	    len = data.get! (ulong[]) [1];
	} else {
	    len = data.get!ulong;
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

    override Feeder merge (Feeder [] elem) {
	auto res = elem [0];
	foreach (it ; 1 .. elem.length)
	    res = Feeder (res.get!(T[]) ~ elem [it].get!(T[]));
	
	return res;
    }
    
    override uint arity () {
	return 1;
    }

    override Task clone () {
	auto ret = new IndexedElem!fun;
	return ret;
    }
    
};

class Repeat(T) : Task {
    mixin NominateTask;

    private Task _task;

    this () {}
    
    this (Task task) {
	this._task = task;
    }

    override Feeder run (Feeder data) {		
	while (data.length!(T) > 1) {	    
	    data = this._task.run (data);
	}
	return Feeder (data);    
    }

    override Feeder merge (Feeder [] elem) {
	auto res = elem [0];
	foreach (it ; 1 .. elem.length) 
	    res = Feeder (res.get!(T[]) ~ elem [it].get!(T[]));
	
	return this.run (res);
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

    override bool needNewExec () {
	return true;
    }
    
    override uint arity () {
	return this._task.arity;
    }

    override Task clone () {
	auto ret = new Repeat!T (this._task.clone);
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
    auto gen = new Stream;
    
    enum n = 1_000_000UL;
    auto begin = Clock.currTime;
    stream.compose (
	Generate! (
	    (ulong i) {
		return (1.0 / n) / ( 1.0 + (( i - 0.5 ) * (1.0 / n)) * (( i - 0.5 ) * (1.0 / n)));
	    }
	),
	Reduce !(
	    (double a, double b) => a + b
	), Map! ((double a) => 4.0 * a)
    );

    auto res = stream.run (n).get!(double []);    
    writefln ("%s %s", res, Clock.currTime - begin);
}

