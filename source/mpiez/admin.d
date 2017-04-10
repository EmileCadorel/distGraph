module mpiez.admin;
import mpi.mpi;
import std.container;
public import mpiez.Process;
public import mpiez.Message;
public import mpiez.global;

class AdminMultipleDefinition : Exception {
    this () {
	super ("Cannot define mutiple administrator");
    }    
}

class Admin (C : Process!P, P : Protocol) {

    private static bool __admLaunched__ = false;

    private C _process;
    
    private P _proto;
    
    this (string [] args) {
	if (!__admLaunched__) {
	    MPI_Init (args);
	    int nprocs, id;
	    MPI_Comm_size (MPI_COMM_WORLD, &nprocs);
	    MPI_Comm_rank (MPI_COMM_WORLD, &id);

	    this._proto = new P (id, nprocs);
	    this._process = new C (args, this._proto);

	    MPI_Barrier (MPI_COMM_WORLD);
	    this._process.routine ();

	    __admLaunched__ = true;
	} else throw new AdminMultipleDefinition ();
    }

    void finalize () {
	MPI_Barrier (MPI_COMM_WORLD);
	this._process.onEnd ();
	MPI_Finalize ();	
    }
    
}

