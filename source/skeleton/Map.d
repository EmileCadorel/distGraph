module skeleton.Map;
import mpiez.admin;
public import skeleton.Register;
import std.traits;
import std.algorithm;
import std.conv;
import utils.Options;
import skeleton.Compose;

private bool checkFunc (alias fun) () {
    isSkeletable!fun;
       
    alias a1 = ParameterTypeTuple! (fun);
    alias r1 = ReturnType!fun;
    static assert (a1.length == 1 && !is (r1 == void), "On a besoin de : T2 function (T, T2 != void) (T)");
    return true;
}


/++
 Execute un fonction de map sur un ensemble d'élément.
 Params:
 fun = un fonction (T2 function (T, T2 != void) (T))
 
 Example:
 ---------
 auto res = ([1, 2]).Map!((int i) => (cast(float) i));
 ---------
+/
template Map (alias fun)
    if (checkFunc!fun) {
    
    alias I = ParameterTypeTuple!(fun) [0];
    alias T2 = ReturnType!fun;


    T2[] map (T2, T : U [], U) (T array) {
	T2 [] res = new T2 [array.length];
	foreach (it ; 0 .. array.length)
	    res [it] = fun (array [it]);
	return res;
    }
    
    /++
     Tout les processus de MPI_COMM_WORLD doivent lancer cette fonction.
     Le résultat se trouve sur le processus 0.
     +/
    U [] Map (T : I []) (T a) {
	auto info = Protocol.commInfo (MPI_COMM_WORLD);
	T [] o;
	int len = cast (int) a.length;
	broadcast (0, cast (int) len, MPI_COMM_WORLD);
	
	scatter (0, len, a, o, MPI_COMM_WORLD);
	auto res = map (o, fun);
	T [] aux;
	gather (0, len, res, aux, MPI_COMM_WORLD);
	return aux;
    }    
}


/++
 Execute un fonction de map sur un ensemble d'élément.
 Params:
 fun = un fonction (T2 function (T, T2 != void) (T))
 
 Example:
 ---------
 auto res = ([1, 2]).MapS!((int i) => (cast(float) i));
 ---------
+/
template MapS (alias fun)
    if (checkFunc !(fun)) {

    alias T = ParameterTypeTuple!(fun) [0];
    alias T2 = ReturnType!fun;
    
    static this () {
	insertSkeleton ("#mapSlave", &mapSlave);
	static if (isFunctionPointer!fun)
	    register.add (fullyQualifiedName!fun, fun);
	else
	    register.add (fullyQualifiedName!fun, &fun);
    }

    T2[] map (T2, T : U [], U) (T array, T2 function (U) op) {
	T2 [] res = new T2 [array.length];
	foreach (it ; 0 .. array.length)
	    res [it] = op (array [it]);
	return res;
    }
    
    class MapProto : Protocol {
	this (int id, int total) {
	    super (id, total);
	    this.send = new Message!(1, T []);
	    this.res = new Message!(2, T2 []);
	}
	
	Message!(1, T []) send;
	Message!(2, T2 []) res;
    }
    
    /++
     Le processus qui lance cette fonction spawn des esclave.
     Params:
     array = le tableau à mapper
     nb = le nombre d'esclave à lancer.
     +/
    T2 [] Map (T [] array, int nb = 2) {
	import std.math;
	auto name = fullyQualifiedName!fun;
	auto func = register.get(name);
	if (func is null)
	    assert (false, "La fonction n'est pas référencé dans la liste des fonctions appelable par les squelettes");

	nb = min (nb, array.length);
	auto proto = new MapProto (0, nb);
	auto slaveComm = proto.spawn!"#mapSlave" (nb, ["--name", name, "--len", to!string(array.length)]);
	proto.send (0, array, slaveComm);
	T2 [] res;
	proto.res.receive (0, res, slaveComm);
	proto.barrier (slaveComm);
	proto.disconnect (slaveComm);
	return res;	
    }
    
    void mapSlave (int id, int total) {
	auto proto = new MapProto (id, total);
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
	auto res = map (o, cast (T2 function (T))(func));
	T2 [] aux;
	gather (0, len, res, aux, MPI_COMM_WORLD);
	
	if (id == 0) {
	    proto.res (0, aux, comm);
	}
	proto.barrier (comm);
	proto.disconnect (comm);
    }
    
}
