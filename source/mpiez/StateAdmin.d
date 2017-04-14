module mpiez.StateAdmin;
import mpiez.Process;
import std.traits, std.typecons;
import utils.Options;
import mpiez.admin;
public import mpiez.Process;
public import mpiez.Message;
public import mpiez.global;
import std.conv;

private bool checkStates (T ...) () {
    foreach (i, t1; T) {
	static if (!is (typeof(t1) == string)) {
	    static if ((is (typeof(&t1) U : U*) && is (U == function)) || (is (t1 T2) && is(T2 == function))) {
		alias a1 = ParameterTypeTuple!(t1);
		alias r1 = ReturnType!(t1);
		static assert (a1.length == 2 && is (a1 [0] == int) && is (a1 [1] == int) && is(r1 == void));
	    } else {
		static assert (is (t1 : Process!P, P : Protocol), t1.stringof ~ " n'est pas un heritier de Process (P : Protocol)");
		static assert (i % 2 == 0 && i != (T.length - 1), "Il manque un clé " ~ to!string (i));
	    }
	} else {
	    static assert (i % 2 == 1, "'" ~ t1 ~ "' ne nomme aucun type");
	    foreach (i2, t2 ; T) {
		static if (is (typeof (t2) == string))
		    static assert (i == i2 || t2 != t1, "Redefinition d'une cle : '" ~ t1 ~ "'"); 
	    }
	}
    }
    return true;
}

class StateAdmin (T ...) {

    static assert (checkStates !(T));

    private Object _process;
    
    private Protocol _proto;   
    
    this (string [] args) {
	import std.stdio;
	if (!__admLaunched__) {
	    MPI_Init (args);
	    Options.init (args);
	    import std.datetime;
	    int nprocs, id;
	    MPI_Comm_size (MPI_COMM_WORLD, &nprocs);
	    MPI_Comm_rank (MPI_COMM_WORLD, &id);
	    alias TYPE = OptionEnum.TYPE;
	    auto res = checkSkeletons (id, nprocs);
	    if (res) return;
	    foreach (i, t1 ; T) {		
		static if (is (typeof (t1) == string)) {
		    if (((Options [TYPE] is null || Options [TYPE].length == 0) && i == 1)
			|| t1 == Options [TYPE]) {
			__admLaunched__ = true;
			alias Type = T[i - 1];
			static if (is (Type : Process!P, P : Protocol)) {
			    alias Proto = TemplateArgsOf!(T [i - 1])  [0]; 
			    this._proto = new Proto (id, nprocs);
			    this._process = new  Type (cast (Proto) this._proto);
			    MPI_Barrier (MPI_COMM_WORLD);
			    (cast (Type) this._process).routine;
			} else {
			    Type (id, nprocs);
			}
		    }
		}		
	    }
	} else throw new AdminMultipleDefinition ();
    }

    bool checkSkeletons (int id, int total) {
	auto type = Options [OptionEnum.TYPE];
	foreach (key, value ; __skeletons__) {
	    if (key == type) {
		value (id, total);
		return true;
	    }
	}
	return false;
    }
    
    void finalize () {
	MPI_Barrier (MPI_COMM_WORLD);
	if (this._process) {
	    delete this._process;
	    delete this._proto;
	}
	MPI_Finalize ();
    }

}
