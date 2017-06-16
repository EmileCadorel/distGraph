module assign.data.Array;
import std.typecons;
import assign.launching;
import assign.Job;
public import assign.data.Data;
import utils.Singleton;
import stdA = std.container;
import std.stdio;
import std.conv, core.exception;

/++
 Classe qui permet d'allouer un tableau sur la ram de différentes machines
+/
class DistArray (T) : DistData {

    alias thisAllocJob = Job!(allocJob, allocRespJob);
    alias thisFreeJob = Job!(freeJob, freeRespJob);
    alias thisIndexJob = Job!(indexJob, indexRespJob);
    alias thisIndexAssignJob = Job!(indexAssignJob, indexAssignRespJob);
    
    /++
     L'index de la première case du tableau local
     +/
    private ulong _begin;    

    /++
     La taille totale du tableau
     +/
    private ulong _length;

    /++
     Table de routage de l'accés au données
     +/
    private Tuple!(ulong, "begin", ulong, "len") [uint] _machineBegins;

    /++
     Les données enregistré dans le tableau localement
     +/
    private T [] _local;    
    
    /++
     Allocation d'un nouveau tableau distribué
     Params:
     length = la taille du tableau
     +/
    this (ulong length) {
	super (computeId ());
	this._length = length;
	auto sizes = Server.getMachinesFreeMemory ();
	writeln ("Free Mem");
	foreach (key, value ; sizes) {
	    writeln (key, " => ", value * 1000);
	}
	
	writeln ("Repartition Mem");
	
	auto repartition = divide (sizes, length);
	foreach (key, value ; repartition) {
	    writeln (key, " => ", value);
	}
	auto machineId = Server.machineId;
	this._local = new T[repartition [machineId].len];
	
	foreach (key, value ; repartition) {
	    if (key != machineId) {
		Server.jobRequest (key, new thisAllocJob (), this._id, length, value.begin, value.len);
		auto res = Server.waitMsg!uint ();
	    }
	}
	
	this._machineBegins = repartition;
	DataTable.add (this);
    }

    /++
     Allocation d'un nouveau tableau, aucune distribution n'est faite dans ce constructeur.
     Params:
     id = l'identifiant du tableau.
     length = la taille du tableau
     localBegin = l'index de la première case du tableau
     localLength = la taille du tableau en mémoire local.
     +/
    private this (uint id, ulong length, ulong localBegin, ulong localLength) {
	super (id);
	this._length = length;
	this._begin = localBegin;
	this._local = new T[localLength];	
	DataTable.add (this);
    }

    private this (uint id, ulong localBegin, T [] data) {
	super (id);
	this._length = 0;
	this._begin = localBegin;
	this._local = data;
	DataTable.add (this);
    }
    
    /++
     Job appeler lors de la récéption d'une demande d'allocation de tableau
     Params:
     addr = la machine originaire de la requête
     total = la taille total du tableau distribué
     begin = l'index de la première case du tableau
     length = la taille du tableau en mémoire local
     +/
    static void allocJob (uint addr, uint id, ulong total, ulong begin, ulong length) {
	writefln ("Allocation requested of size %d", length);	
	auto arr = new DistArray!(T) (id, total, begin, length);
	Server.jobResult (addr, new thisAllocJob (), id);
    }

    /++
     Réponse du job d'allocation
     Params:
     addr = la machine qui a bien éffectuer le travail.
     id = l'identifiant du tableau alloué
     +/
    static void allocRespJob (uint addr, uint id) {
	Server.sendMsg (id);
    }            

    /++
     Calcule l'emplacement de la mémoire en fonction de la capacité des différentes machine connecté
     Params:
     sizes = un tableau associatif de la capacité des machines (taille [id]).
     length = la taille total à allouer
     Returns: un tableau associatif de la répartition de la mémoire.
     +/
    static private Tuple!(ulong, "begin", ulong, "len")[uint] divide (ulong [uint] sizes, ulong length) {
	import std.algorithm;
	
	// Somme en byte de la taille de la mémoire distribué, en double pour pouvoir faire un %
	double sum = cast (double) (
	    (sizes.values.reduce!"a + b" () * 1000 /*La taille est lu en Kb  */)
	    / T.sizeof
	);	
	
	Tuple!(ulong, "begin", ulong, "len") [uint] repartition;
	ulong current = 0, nbMachine = 0;
	
	foreach (key, value ; sizes) {
	    value = (value * 1000) / T.sizeof;
	    ulong len;
	    if (nbMachine != sizes.length - 1)
		len = min (cast (ulong) ((cast (double)(value) / sum) * length), value);
	    else
		len = length - current;
	    
	    repartition [key] = tuple (current, len);
	    current += len;
	    nbMachine ++;
	}	
	return repartition;
    }

    static void indexJob (uint addr, uint id, ulong index) {
	auto array = DataTable.get!(DistArray!T) (id);
	Server.jobResult (addr, new thisIndexJob, id, array._local [index - array._begin]);
    }

    static void indexRespJob (uint addr, uint id, T value) {
	Server.sendMsg (value);
    }	    

    /++ 
     Accède à une case du tableau
     Returns: la case en question
     +/
    const (T) opIndex (ulong index) const {
	if (index < this._local.length) {
	    return this._local [index];
	} else {
	    foreach (key, value ; this._machineBegins) {
		if (index >= value.begin && index < (value.len + value.begin)) {
		    Server.jobRequest (key, new thisIndexJob, this._id, index);
		    return Server.waitMsg!(T) ();
		}
	    }
	    throw new RangeError ();
	}
    }
    
    static void indexAssignJob (uint addr, uint id, ulong index, T value) {
	auto array = DataTable.get!(DistArray!T) (id);
	array._local [index - array._begin] = value;
	Server.jobResult (addr, new thisIndexAssignJob, id);
    }

    static void indexAssignRespJob (uint addr, uint id) {
	Server.sendMsg (id);
    }	    
    
    /++
     Set la valeur d'un case 
     Params:
     value = la valeur à mettre dans la case
     index = l'index de la case en question     
     +/
    void opIndexAssign (T _value, ulong index) {
	if (index < this._local.length) {
	    this._local [index] = _value;
	} else {
	    foreach (key, value; this._machineBegins) {
		if (index >= value.begin && index < (value.len + value.begin)) {
		    Server.jobRequest (key, new thisIndexAssignJob, this._id, index, _value);
		    Server.waitMsg!uint ();
		    return;
		}
	    }
	    throw new RangeError ();
	}
    }
    
    /++
     Returns: la taille total du tableau.
     +/
    ulong length () @property {
	return this._length;
    }    

    /++
     Returns: l'index du premier élément du tableaux
     +/
    ulong begin () @property {
	return this._begin;
    }
    
    /++
     Returns: la taille local du tableau
     +/
    ulong localLength () @property {
	return this._local.length;
    }

    /++
     Returns: les éléments stocker localement.
     +/
    T [] local () @property {
	return this._local;
    }
    
    /++
     Returns: la table de routage du tableau
     +/
    auto machineBegins () @property {
	return this._machineBegins;
    }    
    
    /++
     Job appelé par le destructeur d'un tableau pour libérer la mémoire
     Params:
     addr = la machine originaire du message
     id = l'identifiant du tableau a libérer
     +/
    static void freeJob (uint addr, uint id) {
	writeln ("Free received ", id);
	stdout.flush ();
	DataTable.free (id);
	Server.jobResult (addr, new thisFreeJob (), id);
    }

    /++
     Réponse reçu lorsqu'une machine à bien libérer la mémoire comme demandé
     Params:
     addr = l'identifiant de la machine
     id = l'identifiant du tableau libéré
     +/
    static void freeRespJob (uint addr, uint id) {
	Server.sendMsg (id);
    }
    
    /++
     On libère la mémoire des autres machines.
     +/
    ~ this () {
	writeln ("Destruction du tableau ", this._id);
	stdout.flush ();
	foreach (key, value ; this._machineBegins) {
	    if (key != Server.machineId && Server.isConnected (key)) {
		Server.jobRequest (key, new thisFreeJob, this._id);
		Server.waitMsg!uint ();
	    }
	}	
    }    

};

/++
 Cette fonction est a exécuter sur chaque machine.
 Params:
 id = l'identifiant du futur tableau
 begin = le debut du tableau local
 data = les données à mettre dans le tableau local.
+/
T make (T : DistArray!U, U) (uint id, ulong begin, U [] data) {
    return new DistArray!U (id, begin, data);
}
