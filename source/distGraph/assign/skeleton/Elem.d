module distGraph.assign.skeleton.Elem;
import distGraph.assign.skeleton.Task;
import distGraph.assign.data.Array;
import std.traits, std.typecons;

class Elem (alias fun) : Task {

    enum __ARITY__ = ParameterTypeTuple!(fun).length;
    alias T = ParameterTypeTuple!(fun) [0];
    alias TUPLE = Tuple!(ParameterTypeTuple!(fun));

    override Feeder run (Feeder _in, Feeder _outF = Feeder.empty) {
	T [__ARITY__] aux;
	T [] data = _in.get!(T[]);
	T [] _out;
	if (_outF.isEmpty && _outF.length!(T) >= (data.length / __ARITY__) + (data.length % __ARITY__)) {
	    _out = _outF.get!(T[]) [0 .. (data.length / __ARITY__) + (data.length % __ARITY__)];
	} else {
	    _out = alloc!(T)((data.length / __ARITY__) + (data.length % __ARITY__));
	}
	
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
    
    override Feeder distJob (Feeder) {
	assert (false, "TODO");
    }
    
    override Feeder output (Feeder _in) {
	T [] data = _in.get!(T[]);
	T [] _out = alloc!(T) ((data.length / __ARITY__) + (data.length % __ARITY__));
	return Feeder (_out);
    }
    
    override Feeder [] divide (ulong nb, Feeder _inF) {
	auto _in = _inF.get!(T[]);

	Feeder [] ret = alloc!(Feeder) (nb);	
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

       		  
class IndexedElem (alias fun) : Task {

    enum __ARITY__ = ParameterTypeTuple!(fun).length;
    alias T = ReturnType!fun;
                
    override Feeder run (Feeder _in, Feeder _outF = Feeder.empty) {	
	auto begin = _in.get!(ulong[]) [0];
	T[] _out = _in.get!(T[]);
		
	for (auto i = 0; (i + 1) <= _out.length; i += 1) {
	    _out [i] = fun (i + begin);
	}
	
	return Feeder (_out);
    }

    override DistData distribute (Feeder _in) {
	auto len = _in.get!(ulong);
	return new DistArray!T (len);	
    }

    static void inElemJob (uint addr, uint id, ulong begin) {
	import distGraph.assign.data.Array;
	import distGraph.assign.launching;
	auto array = DataTable.get!(DistArray!T) (id);

	
	//Server.jobResult (addr, new thisJob, arrId);
    }

    static void endJob (uint addr, uint id) {
	//Server.sendMsg (id);
    }        

    override Feeder distJob (Feeder) {
	assert (false, "TODO");
    }
    
    override Feeder [] divide (ulong nb, Feeder _in) {
	Feeder [] ret = alloc!(Feeder) (nb);
	auto len = _in.length!(T);
	auto _out = _in.get!(T[]);
	
	foreach (it ; 0 .. nb) {
	    if (it < nb - 1) {
		ret [it] = Feeder (_out [len / nb * it .. len / nb * (it + 1)]);
		ret [it].get!(ulong[]) [0] = len / nb * it; 
	    } else {
		ret [it] = Feeder (_out [len / nb * it .. $]);
		ret [it].get!(ulong[]) [0] = len / nb * it;
	    }
	}       
	
	return ret;
    }

    override Feeder output (Feeder _in) {
	ulong len;
	if (_in.isArray) {
	    len = _in.get! (ulong[]) [1];
	} else {
	    len = _in.get!ulong;
	}
	
	return Feeder (alloc!(T)(len));	
    }
    
    override Task clone () {
	auto ret = new IndexedElem!fun;
	return ret;
    }
    
};

