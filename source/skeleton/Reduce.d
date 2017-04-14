module skeleton.Reduce;
import mpiez.admin;
public import skeleton.Register;
import std.traits;
import std.algorithm;
import std.conv;
import utils.Options;


private bool checkFunc (alias fun, T) () {
    static assert ((is (typeof(&fun) U : U*) && is (U == function)) || (is (fun T2) && is(T2 == function)));
    alias a1 = ParameterTypeTuple! (fun);
    alias r1 = ReturnType!fun;
    static assert (a1.length == 2 && is (a1[0] == T) && is (a1[1] == T) && is (r1 == T), "On a besoin de : " ~ T.stringof ~ " function (" ~ T.stringof ~ ", " ~ T.stringof ~ ")");
    return true;
}

template Reduce (alias fun, T)
    if (checkFunc !(fun, T)) {

    static this () {
	insertSkeleton ("#reduceSlave", &reduceSlave);
	register.add (fullyQualifiedName!fun, &fun);
    }

    /**
     Lance le squelette
     Params:
     array = le tableau à réduire
     nb = le nombre de worker
     */
    T run (T [] array, int nb = 2) {
	import std.math;
	auto name = fullyQualifiedName!fun;
	auto func = register.get(name);
	if (func is null)
	    assert (false, "La fonction n'est pas référencé dans la liste des fonctions appelable par les squelettes");

	nb = min (nb, array.length);
	auto proto = new ReduceProto!T (0, nb);
	auto slaveComm = proto.spawn!"#reduceSlave" (nb, ["--name", name, "--len", to!string (array.length)]);
	proto.send (0, array, slaveComm);
	T res;
	proto.res.receive (0, res, slaveComm);
	return res;	
    }
    
    U reduce (T : U [], U) (T array, U function (U, U) op) {
	auto res = array [0];
	foreach (it ; 1 .. array.length) {
	    res = op (res, array [it]);
	}
	return res;
    }
    
    class ReduceProto (T) : Protocol {
	this (int id, int total) {
	    super (id, total);
	    this.send = new Message!(1, T []);
	    this.res = new Message!(2, T);
	}

	Message!(1, T []) send;
	Message!(2, T) res;
    }    

    void reduceSlave (int id, int total) {
	auto proto = new ReduceProto!T (id, total);
	auto comm = Protocol.parent ();

	auto len = to!int (Options ["--len"]);
	auto name = Options ["--name"];
	auto func = register.get (name);
	if (func is null)
	    assert (false, "La fonction n'est pas référencé dans la liste des fonctions appelable par les squelettes");

	T [] array;
	if (id == 0) {
	    proto.send.receive (0, array, comm);
	}
    
	T [] o;
	scatter (0, len, array, o, MPI_COMM_WORLD);
	syncWriteln (o);
	auto res = reduce (o, cast (T function (T, T))(func));
	T [] aux;
	gather (0, total, res, aux, MPI_COMM_WORLD);

	if (id == 0) {
	    res = reduce (aux, cast (T function (T, T))(func));
	    proto.res (0, res, comm);
	}
    }
}
