module assign.data.Array;
import std.typecons;
import assign.launching;
import assign.Job;
import utils.Singleton;
import stdA = std.container;
import std.stdio;
import std.conv;

alias ArrayTable = ArrayTableS.instance;

class ArrayTableS {

    private DistArrayS [uint] _arrays;

    /++
     Ajoute un tableau à la liste des tableau connu
     +/
    void add (DistArrayS array) {
	this._arrays [array.id] = (array);
    }

    /++
     Fonction permettant de récupérer un tableau
     Params:
     id = l'identifiant du tableau
     +/
    DistArrayS opIndex (uint id) {
	return this._arrays [id];
    }

    /++
     Fonction permettant de récupérer un tableau directement casté au bon type.
     Params:
     id = l'identifiant du tableau
     +/
    T get (T : DistArrayS) (uint id) {
	return cast (T) (this._arrays [id]);
    }

    /++
     Libère la mémoire du tableau, et le supprime de la liste des tableaux
     Params:
     id = l'identifiant du tableau
     +/
    void free (uint id) {
	if (auto it = id in this._arrays) {
	    writeln ("Ici ", id);
	    stdout.flush ();
	    delete *it;
	    this._arrays.remove (id);
	}
    }

    /++
     Retire le tableau de l'ensemble des tableaux sans le detruire
     Params:
     id = l'identifiant du tableau
     +/
    void remove (uint id) {
	if (auto it = id in this._arrays) {
	    this._arrays.remove (id);
	}
    }
    
    mixin ThreadSafeSingleton;
}

class DistArrayS {

    /++
     L'identifiant du tableau
     +/
    private uint _id;

    this (uint id) {
	this._id = id;
    }

    uint id () const @property {
	return this._id;
    }
    
}

/++
 Classe qui permet d'allouer un tableau sur la ram de différentes machine
+/
class DistArray (T) : DistArrayS {

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
     Les derniers identifiants pour permettre que l'identifiant du tableau soit unique
     +/
    private static uint __lastId__ = 0;
    
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
	ArrayTable.add (this);
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

    /++
     Génération d'un nouvelle identifiant de tableau unique
     Returns: le nouvelle identifiant
     +/
    private static uint computeId () {
	__lastId__ ++;
	return __lastId__ - 1;
    }	

    static void indexJob (uint addr, uint id, ulong index) {
	auto array = ArrayTable.get!(DistArray!T) (id);
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
	    assert (false, "Sortie de tableau, " ~ to!string (index));	    
	}
    }
    
    static void indexAssignJob (uint addr, uint id, ulong index, T value) {
	auto array = ArrayTable.get!(DistArray!T) (id);
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
	    assert (false, "Sortie de tableau, " ~ to!string (index));
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
	ArrayTable.free (id);
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

}
