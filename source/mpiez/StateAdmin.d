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
	    static assert (is (t1 : Process!P, P : Protocol), t1.stringof ~ " n'est pas un heritier de Process (P : Protocol)");
	    static assert (i != (T.length - 1) && (i == 0 || is (typeof (T[i - 1]) == string)), "Il manque un clé " ~ to!string (i));
	} else {
	    static assert (!(is (typeof(t1) == string) && (i == 0 || is (typeof(T [i - 1]) == string))),
							 "'" ~ t1 ~ "' ne nomme aucun type");
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
	    int nprocs, id;
	    MPI_Comm_size (MPI_COMM_WORLD, &nprocs);
	    MPI_Comm_rank (MPI_COMM_WORLD, &id);
	    alias TYPE = OptionEnum.TYPE;
	    foreach (i, t1 ; T) {		
		static if (is (typeof (t1) == string)) {
		    if (((Options [TYPE] is null || Options [TYPE].length == 0) && i == 1)
			|| t1 == Options [TYPE]) {

			alias Proto = TemplateArgsOf!(T [i - 1])  [0]; 
			this._proto = new Proto (id, nprocs);
			alias Type = T[i - 1];
			this._process = new  Type (cast (Proto) this._proto);
			MPI_Barrier (MPI_COMM_WORLD);
			(cast (Type) this._process).routine;
			__admLaunched__ = true;
		    }
		}		
	    }
	} else throw new AdminMultipleDefinition ();
    }
    
    void finalize () {
	MPI_Barrier (MPI_COMM_WORLD);
	delete this._process;
	delete this._proto;
	MPI_Finalize ();
    }

}
