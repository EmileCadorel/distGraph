module distGraph.assign.skeleton.Task;
public import distGraph.utils.Allocation;
import std.container;
import distGraph.assign.data.Data;

struct Feeder {

    private ulong a;
    private void * ax;

    this (T : U [], U) (T a) @nogc {
	this.ax = cast (byte*) a.ptr;
	this.a = a.length * U.sizeof;
    }

    this (T : U*, U) (T a) @nogc {
	this.ax = null;
	this.a = 0;
    }
    
    this (T) (T a) @nogc {	
	*(cast (T*) &this.a) = a;
    }

    this (ulong a, void * ax) {
	this.a = a;
	this.ax = ax;
    }
    
    T get (T) () @nogc {	
	return *(cast (T*) &this.a);
    }

    T get (T : U[], U) () @nogc {
	return (cast (U*)this.ax) [0 .. (this.a / U.sizeof)];
    }    

    T opIndexAssign (T) (ulong id, T data) @nogc {
	this.get!(T[]) [id] = data;
	return data;
    }
    
    ulong length (T) () {
	return this.get!(T[]).length;
    }
        
    bool isArray () @nogc {
	return this.ax !is null;
    }

    static Feeder empty () {
	return Feeder (0, null);
    }

    bool isEmpty () {
	return this.ax is null && this.a == 0;
    }

    ubyte[] toRawData () {
	if (this.isArray) {
	    return (cast (ubyte*) &this.a) [0 .. 8] ~ cast (ubyte[]) this.ax [0 .. this.a];
	} else {
	    return (cast (ubyte*) &this.a) [0 .. 8];
	}
    }

    static Feeder fromRawData (ubyte[] data) {
	auto res = Feeder (0, null);
	res.a = *cast(ulong*) (cast (ubyte[]) data.ptr [0 .. 8]).ptr;
	if (data.length != 8) {
	    res.ax = data.ptr + 8;
	}
	return res;
    }
    
    void concat (Feeder other) {
	if (this.isArray && other.isArray) {
	    auto begin = this.get!(ubyte[]);
	    auto end = other.get!(ubyte[]);
	    auto a = begin ~ end;
	    this.ax = cast (byte*) (a).ptr;
	    this.a = a.length;
	} else if (other.isArray) {
	    this.ax = other.ax;
	    this.a = other.a;
	}
    }
    
}


/++
 Tache élémentaire qui va permettre de renseigner le flux de données.
+/
class Task {
    
    /++
     Le tableau qui va contenir les constructeurs de la fabrique de tâches.
     +/
    __gshared static Array!Task __initializer__;
    
    /++
     Execution de la tâches
     Params:
     i = l'entrée du flux
     Returns: la sortie du flux
     +/
    abstract Feeder run (Feeder i, Feeder o = Feeder.empty);
        
    /++
     Divise un ensemble de données en vue d'une parallélisation
     Params:
     nb = le nombre de division nécéssaire
     i = les données en entrée à diviser
     Returns: un tableau de division (assert (return.length == nb)).
     +/
    abstract Feeder [] divide (ulong nb, Feeder i);

    /++
     Distribue les données sur les différentes machines connectées au serveur
     Params:
     i = les données à distribuer
     Returns: un élement de type distribué
     +/
    abstract DistData distribute (Feeder i);
    
    /++
     Genere le tableau de sortie qui pourra recueillir le resultat du calcul 
     Ne produit aucun calcul
     Params:
     _in = l'entrée qui pourra être envoyer à run dans le futur
     Returns: la sortie avec le bonne taille alloué
     +/
    abstract Feeder output (Feeder _in); 

    /++
     Execute un job sur une machine distante
     Params:
     _in = les données à passer à la machine distante
     Returns: les données retourné par la machine distante
     +/
    abstract Feeder distJob (Feeder _in);
    
    /++
     Crée un clone de la tâche
     Returns: le clone
     +/
    abstract Task clone ();
    
}

class SyncTask : Task {

    /++
     Cette execution se fait sur un seul noeud, après la synchronisation de tout le reste
     Params:
     _in = les données en entrées
     Returns: le resultat de la finalisation
     +/
    abstract Feeder finalize (Feeder[] _in);
    
}
