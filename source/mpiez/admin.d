module mpiez.admin;
import mpi.mpi;
import std.container;
public import mpiez.Process;
public import mpiez.Message;
public import mpiez.global;
public import mpiez.StateAdmin;
import std.stdio;
import utils.Options;

class AdminMultipleDefinition : Exception {
    this () {
	super ("Cannot define mutiple administrator");
    }    
}

static __gshared bool __admLaunched__ = false;

class Admin (C : Process!P, P : Protocol) {

    private C _process;
    
    private P _proto;
    
    this (string [] args) {
	if (!__admLaunched__) {
	    MPI_Init (args);
	    Options.init (args);
	    int nprocs, id;
	    MPI_Comm_size (MPI_COMM_WORLD, &nprocs);
	    MPI_Comm_rank (MPI_COMM_WORLD, &id);

	    this._proto = new P (id, nprocs);
	    this._process = new C (this._proto);

	    MPI_Barrier (MPI_COMM_WORLD);
	    this._process.routine ();

	    __admLaunched__ = true;	    
	} else throw new AdminMultipleDefinition ();
    }

    void finalize () {
	MPI_Barrier (MPI_COMM_WORLD);
	delete this._process;
	delete this._proto;
	MPI_Finalize ();
    }
    
}

