module mpiez.admin;
import mpi.mpi;
import std.container;
public import mpiez.Process;
public import mpiez.Message;
public import mpiez.global;
public import mpiez.StateAdmin;
import std.stdio;
import utils.Options;
import std.traits, std.typecons;

class AdminMultipleDefinition : Exception {
    this () {
	super ("Cannot define mutiple administrator");
    }    
}

static __gshared bool __admLaunched__ = false;


alias Launchable = void function (int, int);
Launchable [string] __skeletons__;

void insertSkeleton (string name, Launchable skel) {
    __skeletons__ [name] = skel;
}

private bool checkT (T ...) () {
    foreach (i, t1 ; T) {
	static if ((is (typeof(&t1) U : U*) && is (U == function)) ||
		   (is (t1 T2) && is(T2 == function))) {	
	    alias a1 = ParameterTypeTuple!(t1);
	    alias r1 = ReturnType!(t1);
	    static assert (a1.length == 2 && is (a1 [0] == int) && is (a1 [1] == int) && is(r1 == void));	
	} else {
	    static assert (is(t1 : Process!P, P : Protocol), t1.stringof ~ " n'est pas un heritier de Process (P : Protocol)");
	}
    }
    return true;
}


class Admin (T...)
    if (T.length == 1)
	{

	    static assert (checkT!T);
    
	    private Object _process;
	    	    
	    private Protocol _proto;
	    
	    this (string [] args) {
		if (!__admLaunched__) {
		    __admLaunched__ = true;	  
		    MPI_Init (args);
		    Options.init (args);
		    int nprocs, id;
		    MPI_Comm_size (MPI_COMM_WORLD, &nprocs);
		    MPI_Comm_rank (MPI_COMM_WORLD, &id);
		    if (checkSkeletons (id, nprocs)) return;
		    alias Type = T[0];
		    static if (is(T[0] : Process!P, P : Protocol)) {
			alias Proto = TemplateArgsOf!Type [0]; 
			this._proto = new Proto (id, nprocs);
			this._process = new Type (this._proto);
			
			MPI_Barrier (MPI_COMM_WORLD);
			(cast (Type)this._process).routine ();
		    } else {
			Type (id, nprocs);
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

