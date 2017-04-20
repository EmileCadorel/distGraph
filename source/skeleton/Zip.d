module skeleton.Zip;
import mpiez.admin, mpiez.Process;
import std.traits;
import skeleton.Compose;

private bool checkFunc (int len, alias fun) () {
    isSkeletable!fun;
    
    alias a1 = ParameterTypeTuple! (fun);
    alias r1 = ReturnType!fun;
    static assert (a1.length == len && !is (r1 == void), "On a besoin de : T2 function (T..., T2 != void) (T)");
    return true;
}

alias Zip (alias fun) = Zip!(2, fun);

template Zip (int len = 2, alias fun)
    if (checkFunc!(len , fun)) {
    
    alias I = ParameterTypeTuple!(fun) [0];
    alias I2 = ParameterTypeTuple!(fun) [0];
    alias U = ReturnType!(fun);

    U[] zip (T : I [], T2 : I2 []) (T a, T2 b) {
	import std.conv;
	auto res = new U [a.length];
	foreach (it ; 0 .. a.length) {
	    res [it] = fun (a [it], b [it]);
	}
	return res;
    }

    U[] Zip (T : I [], T2 : I2 []) (T a, T2 b)  {
	auto info = Protocol.commInfo (MPI_COMM_WORLD);
	T o; T2 i;
	int len = cast (int) a.length;
	broadcast (0, cast (int) len, MPI_COMM_WORLD);
	scatter (0, len, a, o, MPI_COMM_WORLD);
	scatter (0, len, b, i, MPI_COMM_WORLD);
	
	auto res = zip (o, i);
	U [] aux;
	gather (0, len, res, aux, MPI_COMM_WORLD);
	return aux;
    }    
    
}
