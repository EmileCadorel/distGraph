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

    override void run (Feeder _in, Feeder _out) {
	T [__ARITY__] aux;
	T [] data = _in.get!(T[]);		
	uint i = 0;
	for (; (i + __ARITY__) <= data.length; i += __ARITY__) {
	    for (uint j = 0; j < __ARITY__; j++) {
		aux [j] = data [i + j];
	    }
	    
	    TUPLE tu = aux;
	    _out.get!(T[]) [i / __ARITY__] = fun (tu.expand);
	}
	
	for (uint j = 0; (j + i) < data.length; j ++) {
	    _out.get!(T[]) [j + (i / __ARITY__)] = data [i + j];
	}	
    }    
    
    override Feeder [][3] divide (ulong nb, Feeder _inF) {
	auto _in = _inF.get!(T[]);
	auto _out = new T [(_in.length / __ARITY__) + (_in.length % __ARITY__)];	
	if (_in.length == 1) return [[Feeder (_in)], [Feeder (_out)], [Feeder (_out)]];

	Feeder [][3] ret;
	ret[0] = new Feeder [nb];
	ret[1] = new Feeder [nb];
	ret[2] = [Feeder (_out)];
	
	foreach (it ; 0 .. nb) {
	    if (it < nb - 1) {		
		ret [0][it] = Feeder (_in [($ / nb * it) .. ($ / nb) * (it + 1)]);
		ret [1][it] = Feeder (_out [($ / nb * it) .. ($ / nb) * (it + 1)]); 
	    } else {
		ret [0][it] = Feeder (_in [($ / nb) * it .. $]);
		ret [1][it] = Feeder (_out [($ / nb * it) .. $]);
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
            
    override void run (Feeder _in, Feeder _out) {	
	ulong begin, len;
	if (_in.isArray) {
	    begin = _in.get! (ulong[]) [0];
	    len = _in.get! (ulong[]) [1];
	} else {
	    len = _in.get!ulong;
	}
	
	uint i = 0;
	for (; (i + 1) <= len; i += 1) {
	    _out.get!(T[]) [i] = fun (i + begin);
	}
    }    

    override Feeder [][3] divide (ulong nb, Feeder _in) {
	Feeder [][3] ret;
	ret [0] = new Feeder [nb];
	ret [1] = new Feeder [nb];
	ret [2] = new Feeder [1];
	
	auto len = _in.get!ulong;
	auto aux = new T [len];
	ret [2][0] = Feeder (aux);
	
	foreach (it ; 0 .. nb) {
	    if (it < nb - 1) {
		ret [0][it] = Feeder ([len / nb * it, len / nb * (it + 1)]);
		ret [1][it] = Feeder (aux [len / nb * it .. len / nb * (it + 1)]); 
	    } else {
		ret [0][it] = Feeder ([len / nb * it, len - (len / nb * it)]);
		ret [1][it] = Feeder (aux [len / nb * it .. $]);
	    }
	}       
	
	return ret;
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

    override void run (Feeder _in, Feeder _out) {
	auto div = this._task.divide (1, _in);
	while (div [0][0].length!(T) > 1) {	    
	    this._task.run (div [0][0], div [1][0]);
	    div = this._task.divide (1, div [1][0]);
	}
	_out.get!(T[]) [0] = div [0][0].get!(T[]) [0];
    }

    override Feeder finalize (Feeder _in) {
	auto fed = Feeder (new T [1]);
	run (_in, fed);
	return fed;
    }
    
    override Feeder [][3] divide (ulong nb, Feeder _in) {
	Feeder [][3] ret;
	ret [0] = new Feeder [nb];
	ret [1] = new Feeder [nb];
	ret [2] = new Feeder [1];
	
	auto datas = _in.get!(T[]);
	auto aux = new T [nb];
	ret [2][0] = Feeder (aux);
	
	foreach (it ; 0 .. nb) {
	    if (it < nb - 1) {
		ret [0][it] = Feeder (datas [(datas.length / nb * it) .. (datas.length / nb ) * (it + 1)]);
		ret [1][it] = Feeder (aux [it .. it + 1]);
	    } else {
		ret [0][it] = Feeder (datas [(datas.length / nb) * it .. $]);
		ret [1][it] = Feeder (aux [it .. it + 1]);
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
	Map ! (
	    (double a) => 4.0 * a
	)
    );
    
    auto res = stream.run (n).get!(double []);
    writeln (res, " Time : ", Clock.currTime - begin);
    
}

