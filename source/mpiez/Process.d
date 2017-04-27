module mpiez.Process;
public import mpiez.Message;
public import mpi.mpi;

/++
 Classe commune à plusieurs processus qui leurs permet de communiquer.
+/
class Protocol {
    
    /++ L'identifiant du process à qui appartient ce protocol +/
    private int _id;

    /++ Le nombre de processus qui partage le protocol +/
    private int _total;

    
    this (int id, int total) {
	this._id = id;
	this._total = total;	
    }

    /++ 
     Returns: L'identifiant du process à qui appartient ce protocol 
     +/
    const (int) id () const {
	return this._id;	
    }

    /++
     Returns: Le nombre de processus qui partage le protocol 
     +/
    const (int) total () const {
	return this._total;
    }

    /++
     Récupère le status de la communication
     Params:
     proc = le processus source
     tag = l'identifiant du message
     comm = le communicateur
     Returns: le status de la communication
     +/
    static MPI_Status probe (int proc = MPI_ANY_SOURCE, int tag = MPI_ANY_TAG, MPI_Comm comm = MPI_COMM_WORLD) {
	MPI_Status stat;
	MPI_Probe (proc, tag, comm, &stat);
	return stat;
    }

    /++
     Spawn de plusieurs processus sur le schema maître esclave.
     Params:
     worker = le nom du programme à lancer
     nbSpawn = le nombre de process à lancer
     args = les arguments à passer au esclave.
     Returns: un communicateur qui permet de leurs parler.
     +/
    static MPI_Comm spawn (string worker, int nbSpawn, string [] args) {
	import std.string, core.stdc.stdio;
	import utils.Options, std.stdio;	
	if (worker [0] != '.') worker = "./" ~ worker;
	char *[] argv = new char *[args.length];   
	for (int it = 0; it < args.length; it ++) {
	    argv [it] = args [it].toStringz [0 .. args [it].length + 1].dup.ptr;
	}
	
	argv ~= [null];
	auto aux = argv.ptr;	
	if (args.length == 0) 
	    aux = MPI_ARGV_NULL;
	
	MPI_Comm workerComm;
	auto toLaunch = worker.toStringz [0 .. worker.length + 1].dup.ptr;
	MPI_Comm_spawn (toLaunch, cast (char**) aux, nbSpawn, MPI_INFO_NULL, 0, MPI_COMM_SELF, &workerComm, cast(int*) MPI_ERRCODES_IGNORE);
	return workerComm;
    }


    /++
     Spawn de plusieurs processus sur le schema maître esclave.
     Params:
     worker = le nom du squelette à lancer
     nbSpawn = le nombre de process à lancer
     args = les arguments à passer au esclave.
     Returns: un communicateur qui permet de leurs parler.
     +/
    static MPI_Comm spawn (string worker) (int nbSpawn, string [] args) {
	import std.string, core.stdc.stdio;
	import utils.Options, std.stdio;
	args ~= ["-t", worker];
	char *[] argv = new char *[args.length];   
	for (int it = 0; it < args.length; it ++) {
	    argv [it] = cast (char*)(args [it].toStringz [0 .. args [it].length + 1].dup.ptr);
	}
	
	argv ~= [null];
	auto aux = argv.ptr;		
	MPI_Comm workerComm;
	auto process = Options.process;
	if (process [0] != '.') process = "./" ~ process;
	auto toLaunch = cast (char*)(process.toStringz [0 .. process.length + 1].dup.ptr);

	MPI_Comm_spawn (toLaunch, cast (char**) aux, nbSpawn, MPI_INFO_NULL, 0, MPI_COMM_SELF, &workerComm, cast (int*) MPI_ERRCODES_IGNORE);
	return workerComm;
    }
    
    /++
     Spawn de plusieurs processus sur le schema maître esclave.
     Params:
     worker = le nom du squelette à lancer
     nbSpawn = le nombre de process à lancer
     args = les arguments à passer au esclave.
     err = le tableau des erreurs du au lancement (par ref)
     Returns: un communicateur qui permet de leurs parler.
     +/
    static MPI_Comm spawn (string worker) (int nbSpawn, string [] args, ref int [4] err) {
	import std.string, core.stdc.stdio;
	import utils.Options, std.stdio;
	args ~= ["-t", worker];
	char *[] argv = new char *[args.length];   
	for (int it = 0; it < args.length; it ++) {
	    argv [it] = cast (char*)(args [it].toStringz [0 .. args [it].length + 1].ptr);
	}
	
	argv ~= [null];
	auto aux = argv.ptr;		
	MPI_Comm workerComm;
	auto process = Options.process;
	if (process [0] != '.') process = "./" ~ process;
	auto toLaunch = cast (char*)(process.toStringz [0 .. process.length + 1].ptr);
	
	MPI_Comm_spawn (toLaunch, cast (char**) aux, nbSpawn, MPI_INFO_NULL, 0, MPI_COMM_SELF, &workerComm, err.ptr);
	return workerComm;
    }

    /++
     Déconnecte un communicateur de type maître esclave (doit être fait des deux côté de la communication)
     Params:
     comm = le communicateur.
     +/
    static void disconnect (MPI_Comm comm) {
	MPI_Comm_disconnect (&comm);
    }

    /++
     Returns: le communicateur du maître, si le process à été lancé par la méthode spawn.
     +/
    static MPI_Comm parent () {
	MPI_Comm parent;
	MPI_Comm_get_parent (&parent);
	return parent;
    }

    import std.typecons;
    /++
     Récupère les informations d'un communicateur.
     Returns: tuple (id, total);
     +/
    static Tuple!(int, "id", int, "total") commInfo (MPI_Comm comm) {
	int nprocs, id;
	MPI_Comm_size (comm, &nprocs);
	MPI_Comm_rank (comm, &id);
	return Tuple!(int, "id", int, "total") (id, nprocs);
    }

    /++
     Libère un communicateur (ne pas le faire sur MPI_COMM_WORLD);
     +/
    static void freeComm (MPI_Comm comm) {
	int same;
	MPI_Comm_compare (comm, MPI_COMM_WORLD, &same);
	if (same != MPI_SIMILAR)
	    MPI_Comm_free (&comm);
    }

    /++
     Barrière de synchronisation sur un communicateur.
     Params:
     comm = le communicateur à synchroniser
     +/
    static void barrier (MPI_Comm comm) {
	MPI_Barrier (comm);
    }
       
}

/++
 Classe à hériter pour créer un processur lanceable par un admin.
 Params:
 P = le protocol utilisé par le processus.
 +/
class Process (P : Protocol) {

    /++ Le protocol utilisé par le process +/
    protected P _proto;
    
    this (P proto) {
	this._proto = proto;
    }

    /++
     Returns: l'identifiant du processus.
     +/
    int thisId () const {
	return this._proto.id;
    }

    /++
     Returns: le nombre de processus 
     +/
    int worldNb () const {
	return this._proto.total;
    }

    alias spawn = this._proto.spawn;
    alias freeComm = this._proto.freeComm;
    alias parent = this._proto.parent;
    
    /++
     Fonction lancé au démarrage du processus par l'admin.
     +/
    abstract void routine ();
    
    ~this () {
    }
    
}
