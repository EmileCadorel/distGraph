module assign.skeleton.Task;
import std.container;

struct Feeder {

    private ulong a;
    private void * ax;
    private ulong _id;
    
    this (T : U [], U) (T a) @nogc {
	this.ax = cast (byte*) a.ptr;
	this.a = a.length * U.sizeof;
    }
    
    this (T) (T a) @nogc {
	*(cast (T*) &this.a) = a;
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
	} else if (!this.isArray) {
	    assert (false, "Concat ne fonctionne qu'avec des tableaux");
	}
    }
    
    ref ulong id () {
	return this._id;
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
    abstract Feeder run (Feeder i) ;
        
    /++
     Divise un ensemble de données en vue d'une parallélisation
     Params:
     nb = le nombre de division nécéssaire
     i = les données en entrée à diviser
     Returns: un tableau de division (assert (return.length == nb)).
     +/
    abstract Feeder [] divide (ulong nb, Feeder i) ;
    
    /++
     Clone la tâche sans ses attributs (pour la sérialisation)
     Returns: une nouvelle tâche
     +/
    abstract Task simpleClone ();

    /++
     Met à jour un attribut de la classe en fonction de son emplacement
     Params:
     pos = la position de l'attribut
     val = la valeur à donner     
     +/
    abstract void set (ulong pos, Object val);
    
    /++
     Crée un clone de la tâche
     Returns: le clone
     +/
    abstract Task clone ();

    /++
     Fonction utilisé pour la serialisation, et le passage de tâche vers d'autre machines.
     Returns: l'object sérialisé.
     +/
    abstract string serialize ();

    /++
     Récupère l'indentifiant de la tâche pour la sérialisation
     Returns: l'identifiant de la tâches (commun à toutes les tâches identique)
     +/
    abstract ulong id ();
    
}

mixin template BindableDef () {
    import std.path, std.traits;
    struct location {
	string name;
	ulong loc;
    }
    
    string [location] all () {
	return __std__;
    }    

    final override void set (ulong attr, Object elem) {
	
	void set (ulong nb) (ulong attr, Object elem) {
	    static if (nb < this.tupleof.length) {		
		if (nb == attr) {
		    static if (is (typeof(this.tupleof [nb]) : Object)) 
			this.tupleof [nb] = cast (typeof(this.tupleof [nb])) elem;
		} else {
		    set!(nb + 1) (attr, elem);
		}
	    }
	}
	
	set!0 (attr, elem);		
    }
    
    private {	       
	static void init (T) () {
	    T elem;
	    pack ! ((elem).tupleof.length, T) (elem);
	}
	
	static void pack (int nb, T) (T elem) {
	    pack !(nb - 1, T) (elem);
	    immutable name = extension (elem.tupleof[nb - 1].stringof) [1 .. $];
	    static if (name != "__std__") {
		__std__ [location (name, nb - 1)] = fullyQualifiedName!(typeof ((elem).tupleof [nb - 1]));
	    }
	}
	
	static void pack (int nb : 0, T) (T) {}	
	static string [location] __std__;
	static string __name__;
    }        
}

/++
 Mixin qui va permettrent l'insertion des instances de task dans la fabrique
 +/
mixin template NominateTask () {
    import std.outbuffer, std.string;
    
    /++
     L'identifiant de la tâche pour la sérialisation
     +/
    static ulong __id__;
    
    mixin BindableDef;
    
    static assert (is (typeof (this) : Task));    
    static this () {
	init!(typeof(this));
	__id__ = __initializer__.length;
	__initializer__.insertBack (new typeof (this));
    }

    override ulong id () {
	return __id__;
    }
    
    private Task isTask (ulong nb, T) (ulong loc, T elem) {
	static if (nb < elem.tupleof.length) {
	    if (loc == nb) 
		static if (is (typeof (elem.tupleof [nb]) : Task))
		    return elem.tupleof [nb];
		else return null;
	    else
		return isTask! (nb + 1) (loc, elem);
	} else return null;
    }

    final override Task simpleClone () {
	return new typeof (this);
    }
    
    /++
     Surcharge de la serialisation
     +/
    final override string serialize () {
	auto buf = new OutBuffer ();
	
	buf.writef ("%s", __id__);
	foreach (key, value ; __std__) {
	    if (auto task = isTask!0 (key.loc, this)) {
		buf.write ("#");
		buf.writef ("(%s!%s)", key.loc, task.id);
	    }
	}
	
	return buf.toString;
    }        
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
