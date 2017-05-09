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

/++
 Exception jeté, lorsque plusieurs instance d'admin sont créées
+/
class AdminMultipleDefinition : Exception {
    this () {
	super ("Cannot define mutiple administrator");
    }    
}

/++ Il existe un admin +/
static __gshared bool __admLaunched__ = false;

/++ L'admin à lancé la procedure de fin du context MPI  +/
static __gshared bool __finalized__ = false;

/++ Une fonction qui peut être lancé par l'admin doit accepter deux entiers en paramètre. +/
alias Launchable = void function (int, int);

/++ Liste des fonctions de lancement de squelette +/
Launchable [string] __skeletons__;


/++
 Returns: Il existe un admin qui à lancer le contexte MPI ?
+/
bool MPIContext () {
    return __admLaunched__;
}

/++
 Met fin au contexte MPI.
+/
void finalize () {
    __finalized__ = true;
    MPI_Finalize ();
}

/++
 Ajoute un squelette à la liste des squelette que l'admin peut lancer.
 Doit être appeler avant l'instanciation d'un admin pour fonctionner.
+/
void insertSkeleton (string name, Launchable skel) {
    __skeletons__ [name] = skel;
}

/++
 Verifie que les paramètre templates sont admissible pour l'admin.
+/
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

	    /++ Le processus lancé par l'admin +/ 
	    private Object _process;

	    /++ Le protocol utilisé par le processus +/
	    private Protocol _proto;

	    /++ L'admin a lancé un squelette +/
	    private bool _skel;

	    /++
	     Params:
	     args = les paramètres passé au programme
	     +/
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
			this._process = new Type (cast (Proto) this._proto);
			
			MPI_Barrier (MPI_COMM_WORLD);
			(cast (Type)this._process).routine ();
		    } else {
			Type (id, nprocs);
		    }
		      
		} else throw new AdminMultipleDefinition ();
	    }

	    /++
	     On lance le squelette si il existe (son nom est donnée par OptionEnum.TYPE)
	     Params:
	     id = l'identifiant MPI
	     total = le nombre de totaux de processus MPI dans MPI_COMM_WORLD.
	     +/
	    bool checkSkeletons (int id, int total) {
		auto type = Options [OptionEnum.TYPE];
		foreach (key, value ; __skeletons__) {
		    if (key == type) {
			this._skel = true;
			value (id, total);
			return true;
		    }
		}
		return false;
	    }

	    /++
	     On met fin au context MPI, si c'est pas déjà fais.
	     On appel le destructeur du processus.
	     +/
	    void finalize () {
		if (!__finalized__) {
		    MPI_Barrier (MPI_COMM_WORLD);
		    if (this._process) {
			delete this._process;
			delete this._proto;
		    }
		    __finalized__ = true;
		    MPI_Finalize ();
		}		
	    }
    
}

