module skeleton.Generate;
import mpiez.admin;
public import skeleton.Register;
import std.traits;
import std.algorithm;
import std.conv;
import utils.Options;

private bool checkFunc (alias fun) () {
    static assert ((is (typeof(&fun) U : U*) && (is (U == function)) ||
		    is (typeof (&fun) U == delegate)) ||
		   (is (fun T2) && is(T2 == function)) || isFunctionPointer!fun);
    
    alias a1 = ParameterTypeTuple! (fun);
    alias r1 = ReturnType!fun;
    static if (a1.length == 1) {
	static assert (is (a1[0] : ulong) && !is (r1 == void), "On a besoin de : T function (T, I : ulong) (I)");
    } else {
	static assert (a1.length == 2 && is (a1[0] : ulong) && is (a1[1] : ulong) && !is (r1 == void), "On a besoin de : T function (T, I : ulong) (I)");
    }

    return true;
}

template Generate (alias fun)
    if (checkFunc!fun) {

    alias T = ReturnType!fun;
    alias I = ParameterTypeTuple!(fun) [0];
    enum PARAMLENGTH = ParameterTypeTuple!(fun).length;
    
    static if (PARAMLENGTH == 2) {
	alias N = ParameterTypeTuple!(fun) [1];
    }	
    
    static this () {
	insertSkeleton ("#generateSlave", &generateSlave);
	static if (isFunctionPointer!fun)
	    register.add (fullyQualifiedName!fun, fun);
	else
	    register.add (fullyQualifiedName!fun, &fun);
    }

    class GenerateProto : Protocol {
    	this (int id, int total) {
	    super (id, total);
	    this.res = new Message!(1, T []);	    
	}

	Message!(1, T []) res;
    }

    T generate (T : U [], U, I) (ulong begin, T array, U function (I) op) {
	import std.conv;
	foreach (i, it ; array) {
	    array [i] = op (to!I (i + begin));
	}
	return array;
    }

    T generate (T : U [], U, I, N) (ulong begin, ulong len, T array, U function (I, N) op) {
	import std.conv;
	foreach (i, it ; array) {
	    array [i] = op (to!I (i + begin), to!N (len));
	}
	return array;
    }    
    
    T [] run (ulong len, int nb = 2) {
	import std.math;
	auto name = fullyQualifiedName!fun;
	auto func = register.get(name);
	if (func is null)
	    assert (false, "La fonction n'est pas référencé dans la liste des fonctions appelable par les squelettes");

	nb = min (nb, len);
	auto proto = new GenerateProto (0, nb);
	auto slaveComm = proto.spawn!"#generateSlave" (nb, ["--name", name, "--len", to!string(len)]);
	
	T [] res;
	proto.res.receive (0, res, slaveComm);
	barrier (slaveComm);
	
	proto.disconnect (slaveComm);
	return res;	
    }
    
    void generateSlave (int id, int total) {
	auto proto = new GenerateProto (id, total);
	auto comm = Protocol.parent ();

	auto len = to!int (Options ["--len"]);
	auto name = Options ["--name"];
	auto func = register.get (name);
	if (func is null)
	    assert (false, "La fonction n'est pas référencé dans la liste des fonctions appelable par les squelettes");


	auto pos = computeLen (len, id, total);
    	auto o = new T [pos.len];
	T[] res;
	static if (PARAMLENGTH == 1)
	    res = generate (pos.begin, o, cast (T function (I))(func));	    
	else
	    res = generate (pos.begin, len, o, cast (T function (I, N))(func));
	
	T [] aux;
	gather (0, len, res, aux, MPI_COMM_WORLD);
	barrier (MPI_COMM_WORLD);
	if (id == 0) {
	    proto.res.ssend (0, aux, comm);
	}
	
	barrier (comm);	
	proto.disconnect (comm);
    }
    
     
    
}
