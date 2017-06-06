module assign.skeleton.Stream;
import std.concurrency;
import std.container, std.array;

struct Feeder {

    ulong a;
    void * ax;
    Task _task;
    
    this (Task task) {
	this._task = task;
    }

    this (T : U [], U) (T a) @nogc {
	this.ax = cast (byte*) a.ptr;
	this.a = a.length;
    }
    
    this (T) (T a) @nogc {
	*(cast (T*) &this.a) = a;
    }
        
    T get (T) () @nogc {	
	return *(cast (T*) &this.a);
    }

    T get (T : U[], U) () @nogc {	
	return (cast (U*)this.ax) [0 .. this.a];
    }    

    ulong length (T) () {
	return this.get!(T[]).length;
    }
    
    Feeder run (Feeder fed) {
	return this._task.run (fed);
    }
    
    bool isArray () @nogc {
	return this.ax !is null;
    }

    bool isTask () @nogc {
	return this._task !is null;
    }

    Task task () @nogc {
	return this._task;
    }

    Feeder clone () {
	if (this._task) {
	    return Feeder (this._task.clone());
	} else {
	    return this;
	}
    }

    string serialize () {
	return this._task.serialize;
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
     Returns: la valeur de la tâche.
     +/
    abstract Feeder run (Feeder) ;

    /++
     Returns: La tâche n'a pas besoin de synchronisation à la fin, pour que les données soit valide  
     +/
    bool isOutCuttable () {
	return true;
    }
        
    /++
     Divise un ensemble de données en vue d'une parallélisation
     Params:
     nb = le nombre de division nécéssaire
     data = les données à diviser
     Returns: un tableau de division (assert (return.length == nb)).
     +/
    abstract Feeder[] divide (ulong nb, Feeder data) ;

    /++
     Fusionne plusieurs ensemble en vue d'une récupération des éléments parallélisé
     Params:
     data = les données à fusionner
     Returns: un nouvelle ensemble
     +/
    abstract Feeder merge (Feeder [] data);
    

    abstract Task simpleClone ();

    abstract void set (ulong, Object);
    
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

/++
 Classe utilisé pour définir un flux de données entre les différents squelettes.
+/
class Stream {
    import utils.syntax.Lexer;
    
    private DList!Task _tasks;

    this () {}

    void compose (T : Task, TNext ...) (T task, TNext nexts) {
	static if (nexts.length > 0) 
	    compose (nexts);
	this._tasks.insertFront (task);
    }

    private Stream clone () {
	auto res = new Stream;
	foreach (it ; this._tasks)
	    res._tasks.insertBack (it.clone ());
	return res;
    }
    
}

import std.stdio;

private void spawned (Tid own, shared Feeder *sdata) {
    auto fed = (cast (Feeder) *sdata);
    
    while (true) {
	auto task = cast (Task) receiveOnly!(shared (Task));
	if (task !is null) {
	    fed = task.run (fed);
	    if (!task.isOutCuttable) break; // Besoin d'une synchronisation
	} else break;
    }
    
    *sdata = cast (shared(Feeder)) fed;
    send (own, true);
}

private Feeder execTask (Task t, Feeder datas, ref ulong nb, shared (Feeder)* [] ptr, Tid [] sp) {
    foreach (it ; 1 .. nb) {
	send (sp [it - 1], cast (shared (Task)) t.clone ());
    }
	    
    auto feed = t.run (datas);
    if (!t.isOutCuttable) { // Besoin d'une synchro
	Array!Feeder res = make!(Array!Feeder) (feed);
	foreach (it ; 1 .. nb) {
	    receiveOnly!bool;
	    res.insertBack (cast (Feeder) *ptr [it]);
	}
	nb = 1;
	return t.merge (res.array ());
    }
    return feed;
}

shared(Feeder)* [] spawnHelp (ulong nb, Feeder data, Task task, ref Tid [] sp) {
    auto div = task.divide (nb, data);
    if (div !is null) {
	shared (Feeder)* [] ptr = new shared (Feeder*) [div.length];
	foreach (it ; 0 .. div.length)
	    ptr [it] = cast (shared (Feeder)*) &div [it];	

	sp = new Tid [nb - 1];
	foreach (it ; 1 .. nb) {
	    sp [it - 1] = spawn (&spawned, thisTid, ptr [it]);
	}
	return ptr;
    }
    return null;
}

Feeder run (T) (Stream str, T data) {
    return run (str, Feeder (data));
}

Feeder run (Stream str, Feeder data) {
    ulong nb = 1, totalHelp = 2;
    auto feed = Feeder (data);

    shared (Feeder)* [] ptr;
    Tid [] ids;
    foreach (it ; str._tasks) {
	if (nb < totalHelp) {
	    ptr = spawnHelp (totalHelp, feed, it, ids);
	    if (ptr !is null) {
		feed = cast (Feeder) *ptr [0];
		nb = totalHelp;
	    }
	}
	feed = execTask (it, feed, nb, ptr, ids);
    }    

    Array!Feeder res = make!(Array!Feeder) (feed);
    foreach (it ; 1 .. nb) {
	receiveOnly!bool;
	res.insertBack (cast (Feeder) *ptr [it]);
    }

    return str._tasks.back.merge (res.array ());    
}
