module mpiez.Process;
public import mpiez.Message;
public import mpi.mpi;

class Protocol {
    private int _id;
    
    private int _total;

    this (int id, int total) {
	this._id = id;
	this._total = total;	
    }

    const (int) id () const {
	return this._id;	
    }

    const (int) total () const {
	return this._total;
    }

    final MPI_Status probe (int proc = MPI_ANY_SOURCE, int tag = MPI_ANY_TAG, MPI_Comm comm = MPI_COMM_WORLD) const {
	MPI_Status stat;
	MPI_Probe (proc, tag, comm, &stat);
	return stat;
    }
    
}

class Process (P : Protocol) {

    protected P _proto;

    private MPI_Comm _parentComm = null;
    
    this (P proto) {
	this._proto = proto;
    }

    int thisId () const {
	return this._proto.id;
    }

    int worldNb () const {
	return this._proto.total;
    }
    
    abstract void routine ();

    final protected MPI_Comm spawn (string worker, int nbSpawn, string [] args) {
	import std.string, core.stdc.stdio;
	import utils.Options, std.stdio;	
	if (worker [0] != '.') worker = "./" ~ worker;
	char *[] argv = new char *[args.length];   
	for (int it = 0; it < args.length; it ++) {
	    argv [it] = args [it].toStringz [0 .. args [it].length + 1].dup.ptr;
	}
	
	auto aux = argv.ptr;	
	if (args.length == 0) 
	    aux = MPI_ARGV_NULL;
	
	MPI_Comm workerComm;
	MPI_Comm_spawn (worker.dup.ptr, cast (char**) aux, nbSpawn, MPI_INFO_NULL, 0, MPI_COMM_SELF, &workerComm, cast(int*) MPI_ERRCODES_IGNORE);
	return workerComm;
    }
    
    final protected MPI_Comm spawn (string worker) (int nbSpawn, string [] args) {
	import std.string, core.stdc.stdio;
	import utils.Options, std.stdio;
	args ~= ["-t", worker];
	
	char *[] argv = new char *[args.length];   
	for (int it = 0; it < args.length; it ++) {
	    argv [it] = args [it].toStringz [0 .. args [it].length + 1].dup.ptr;
	}
	
	auto aux = argv.ptr;	
	if (args.length == 0) 
	    aux = MPI_ARGV_NULL;
	
	MPI_Comm workerComm;
	MPI_Comm_spawn (Options.process.dup.ptr, cast (char**) aux, nbSpawn, MPI_INFO_NULL, 0, MPI_COMM_SELF, &workerComm, cast(int*) MPI_ERRCODES_IGNORE);
	return workerComm;
    }    
    
    final protected MPI_Comm parent () {
	if (!this._parentComm)
	    MPI_Comm_get_parent (&this._parentComm);
	return this._parentComm;
    }

    final protected void freeComm (MPI_Comm comm) {
	int same;
	MPI_Comm_compare (comm, MPI_COMM_WORLD, &same);
	if (same != MPI_SIMILAR)
	    MPI_Comm_free (&comm);
    }

    import std.typecons;
    final protected Tuple!(int, "id", int, "total") commInfo (MPI_Comm comm) {
	int nprocs, id;
	MPI_Comm_size (comm, &nprocs);
	MPI_Comm_rank (comm, &id);
	return Tuple!(int, "id", int, "total") (id, nprocs);
    }
    
    ~this () {
    }
    
}
