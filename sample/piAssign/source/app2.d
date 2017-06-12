import assign.skeleton.Stream;
import std.stdio;
import std.traits;
import std.datetime;
import std.concurrency;
import std.typecons;
import std.functional;

class Elem (alias FUN) : Task {
    mixin NominateTask;

    alias fun = binaryFun!FUN;
    enum __ARITY__ = ParameterTypeTuple!(fun).length;
    alias T = ParameterTypeTuple!(fun) [0];
    alias TUPLE = Tuple!(ParameterTypeTuple!(fun));

    override Feeder run (Feeder _in) {
	T [__ARITY__] aux;
	T [] data = _in.get!(T[]);
	auto _out = new T [(data.length / __ARITY__) + (data.length % __ARITY__)];
	uint i = 0;
	
	for (; (i + __ARITY__) <= data.length; i += __ARITY__) {
	    for (uint j = 0; j < __ARITY__; j++) {
		aux [j] = data [i + j];
	    }
	    
	    TUPLE tu = aux;
	    _out [i / __ARITY__] = fun (tu.expand);
	}
	
	for (uint j = 0; (j + i) < data.length; j ++) {
	    _out [j + (i / __ARITY__)] = data [i + j];
	}
	return Feeder (_out);
    }    
    
    override Feeder [] divide (ulong nb, Feeder _inF) {
	auto _in = _inF.get!(T[]);

	Feeder [] ret = new Feeder [nb];	
	foreach (it ; 0 .. nb) {
	    if (it < nb - 1) {		
		ret [it] = Feeder (_in [($ / nb * it) .. ($ / nb) * (it + 1)]);
	    } else {
		ret [it] = Feeder (_in [($ / nb) * it .. $]);
	    }
	}
	return ret;
    }
    
    override Task clone () {
	auto ret = new Elem!fun ();
	return ret;
    }

    
};
       		  
class IndexedElem (alias FUN) : Task {
    mixin NominateTask;

    alias fun = binaryFun!FUN;
    enum __ARITY__ = ParameterTypeTuple!(fun).length;
    alias T = ReturnType!fun;
            
    override Feeder run (Feeder _in) {	
	ulong begin, len;
	if (_in.isArray) {
	    begin = _in.get! (ulong[]) [0];
	    len = _in.get! (ulong[]) [1];
	} else {
	    len = _in.get!ulong;
	}
	
	auto _out = new T [len];
	uint i = 0;
	for (; (i + 1) <= len; i += 1) {
	    _out [i] = fun (i + begin);
	}
	return Feeder (_out);
    }    

    override Feeder [] divide (ulong nb, Feeder _in) {
	Feeder [] ret = new Feeder [nb];
	auto len = _in.get!(ulong);
	
	foreach (it ; 0 .. nb) {
	    if (it < nb - 1) {
		ret [it] = Feeder ([len / nb * it, len / nb]);
	    } else {
		ret [it] = Feeder ([len / nb * it, len - (len / nb * (nb - 1))]);
	    }
	}       
	
	return ret;
    }

    override Task clone () {
	auto ret = new IndexedElem!fun;
	return ret;
    }
    
};

class Repeat(T) : SyncTask {
    mixin NominateTask;

    private Task _task;

    this () {}
    
    this (Task task) {
	this._task = task;
    }

    override Feeder run (Feeder _in) {
	auto _out = _in;
	while (_out.length!(T) > 1) {	    
	    _out = this._task.run (_out);
	}
	return _out;
    }

    override Feeder finalize (Feeder [] _in) {
	auto total = 0;
	foreach (it ; _in) {
	    total += it.length!(T);
	}
	auto res = new T [total];
	ulong i = 0;
	
	foreach (it ; _in) {
	    foreach (_i; 0 .. it.length!(T)) {
		res[i] = it.get!(T[])[_i];
		i++;
	    }
	}

	auto fed = run (Feeder (res));
	writeln (fed.get!(T[]));
	return fed;
    }
    
    override Feeder [] divide (ulong nb, Feeder _in) {
	Feeder [] ret = new Feeder [nb];	
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

template Reduce (alias fun) {
    alias T = ReturnType!fun;

    auto Reduce () {       
	return new Repeat!T (
	    new Elem!(fun) 	    
	);
    }
}

template Map (alias fun) {
    auto Map () {
	return new Elem!(fun);	    
    }
}

template Generate (alias fun) {
    auto Generate () {
	return new IndexedElem!fun;	
    }
    
}

void main2 () {    
    auto stream = new Stream;
    auto gen = new Stream;
    
    enum n = 1_000_000UL;
    auto begin = Clock.currTime;
    stream.pipe (
		 Generate! (
			    (ulong i) => (1.0 / n) / ( 1.0 + (( i - 0.5 ) * (1.0 / n)) * (( i - 0.5 ) * (1.0 / n)))
			    ),
		 Reduce!(
			 (double a, double b) => a + b
			 ),
		 Map !(
		       (double a) => a * 4.0
		       )
		 );
    
    auto res = stream.run (n).get!(double []);
    writeln (res, " Time : ", Clock.currTime - begin);
    
}

