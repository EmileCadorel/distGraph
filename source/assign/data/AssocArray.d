module assign.data.AssocArray;
import assign.Job;
public import assign.data.Data;
import utils.Singleton;
import stdA = std.container;
import std.stdio, std.conv;
import assign.launching;
import core.exception;
import std.traits;

/++
 Classe permettant d'allouer un tableau associatif sur différentes machines
 Contrairement au autre type de données distribué, leurs emplacements mémoire ne dépend pas des capacité des différentes machines.
 Chaque machine va le remplir en fonction des autres données dont il dispose (squelette, graphe ...).
 +/
class DistAssocArray (K, V) : DistData {
    static assert (!is(K : Object) && !is(V : Object), "Les données distribué ne peuvent être des pointeurs");
    
    alias thisRegJob = Job!(regJob, regJobEnd);
    alias thisIndexJob = Job!(indexJob, indexJobEnd);
    alias thisAssignJob = Job!(assignJob, assignJobEnd);
    alias thisGetLength = Job!(getLenJob, getLenJobEnd);
    alias thisStringJob = Job!(toStringJob, toStringJobEnd);
    
    
    /++ Les données enregistré dans le tableau assoc local +/
    private V [K] _local;
    
    this () {
	super (computeId ());
	foreach (it ; Server.connected) {
	    Server.jobRequest (it, new thisRegJob, this._id);
	}

	foreach (it ; Server.connected) {
	    Server.waitMsg!(uint);
	}
    }
    
    private this (uint id) {
	super (id);
    }
    
    static void regJob (uint addr, uint id) {
	DataTable.add (new DistAssocArray! (K, V) (id));
	Server.jobResult (addr, new thisRegJob, id);
    }

    static void regJobEnd (uint addr, uint id) {
	Server.sendMsg (id);
    }
    
    static void indexJob (uint addr, uint id, K index) {
	auto array = DataTable.get!(DistAssocArray! (K, V)) (id);
	auto val = index in array._local;
	if (val !is null) {
	    Server.jobResult (addr, new thisIndexJob, id, true, *val);
	} else {
	    Server.jobResult (addr, new thisIndexJob, id, false, V.init);
	}
    }

    static void indexJobEnd (uint addr, uint id, bool returned, V value) {
	Server.sendMsg (returned, value);
    }
    
    /++
     Récupère une valeur sur le tableau totale, peut aller chercher les données sur les machines voisines.
     Params:
     index = l'index de l'élement demandé.
     Returns: l'élement demandé
     Throws: core.exception.RangeError
     +/
    const (V) opIndex (const K index) const {
	auto id = index in this._local;
	if (id !is null) return *id;
	else {
	    bool returned = false;
	    V result;
	    foreach (it ; Server.connected) {		
		Server.jobRequest (it, new thisIndexJob, this._id, index);
		Server.waitMsg (returned, result);
		if (returned) return result;
	    }
	    // Si on est ici personne ne possède la valeur
	    throw new RangeError ();
	}
    }

    /++
     Met à jour la valeur dans le tableau si elle existe déjà     
     Cette fonction renvoi vrai sur serveur si la clé existait, faux sinon
     Params:
     addr = la machine originaire de la requete
     id = l'identifiant du tableau à mettre à jour
     key = la clé ou placer la valeur
     value = la nouvelle valeur.     
     +/
    static void assignJob (uint addr, uint id, K key, V value) {
	auto array = DataTable.get!(DistAssocArray!(K, V)) (id);
	auto it = key in array._local;
	if (it !is null) {
	    *it = value;
	    Server.jobResult (addr, new thisAssignJob, id, true);
	} else {
	    Server.jobResult (addr, new thisAssignJob, id, false);
	}	
    }

    /++
     Renvoi la valeur récupéré par le serveur au main thread.
     +/
    static void assignJobEnd (uint addr, uint id, bool hasIt) {
	Server.sendMsg (hasIt);
    }
    
    /++
     Assigne une valeur à un index. Met à jour si l'index existe déjà (peut demander au machines voisine de mettre à jour leurs données).
     Params:
     value = la valeur à mettre à l'index 
     index = l'index où placer la valeur.     
     +/
    void opIndexAssign (V value, K index) {
	auto id = index in this._local;
	if (id !is null) *id = value;
	else {
	    foreach (it ; Server.connected) {
		Server.jobRequest (it, new thisAssignJob, this._id, index, value);
		if (Server.waitMsg !(bool)) return;
	    }
	    // Si on est la, c'est que personne ne possède la valeur et on la stocke en local.
	    this._local [index] = value;
	}
    }

    /++
     Returns: les informations stocké localement.
     +/
    ref V [K] local () {
	return this._local;
    }

    static void getLenJob (uint addr, uint id) {
	auto assoc = DataTable.get!(DistAssocArray!(K, V)) (id);
	Server.jobResult (addr, new thisGetLength, id, assoc.local.length);
    }

    static void getLenJobEnd (uint addr, uint id, ulong len) {
	Server.sendMsg (len);
    }
    
    /++
     Returns: la taille totale du tableau
     +/
    const (ulong) length () {
	auto localLen = this._local.length;
	foreach (it ; Server.connected) {
	    Server.jobRequest (it, new thisGetLength, this._id);	    
	}

	foreach (it ; Server.connected) {
	    localLen += Server.waitMsg!(ulong);
	}
	return localLen;
    }
    
    /++
     Place la valeur à l'index dans les informations local à la machine.
     Params:
     index = l'index où placer la valeur.
     value = la valeur à placer dans le tableau     
     +/
    void localSet (K index, V value) {
	this._local [index] = value;
    }
        
    static void toStringJob (uint addr, uint id) {
	import std.conv;
	auto assoc = DataTable.get!(DistAssocArray!(K, V)) (id);
	Server.jobResult (addr, new thisStringJob, id, assoc.local.to!string);
    }

    static void toStringJobEnd (uint addr, uint id, string val) {
	Server.sendMsg (val);
    }

    
    override string toString () {
	import std.outbuffer, std.conv;
	auto buf = new OutBuffer ();
	buf.writefln ("{\n\t%s", this._local.to!string);
	foreach (it ; Server.connected) {
	    Server.jobRequest (it, new thisStringJob, this._id);
	}
	foreach (it ; Server.connected) {
	    buf.writefln ("\t%s", Server.waitMsg!(string));
	}
	buf.write ("}\n");
	return buf.toString;	
    }
    
    
}
