module assign.skeleton.Stream;
import std.container;

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

    Feeder run (Feeder fed) {
	this._task.feed (fed);
	return this._task.run ();
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
     La tâche suivante à éffectuer.
     +/
    private Feeder _next;

    /++
     La tâche possède assez de données pour être lancé
     +/
    abstract bool full ();

    /++
     Execution de la tâches
     Returns: la valeur de la tâche.
     +/
    abstract Feeder run () ;

    /++
     Le nombre de donnée requise par la tâche
     +/
    abstract uint arity () ;
    
    /++
     Ajoute une données dans la tâche, qu'elle devra consommé.
     Params:
     data = la données à consommer.
     +/
    abstract void feed (Feeder data) ;    

    /++
     La tâche est la première à être lancé
     +/
    Feeder runAsFirst () {
	return this.run;
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
     Returns: La tâche qui va ếtre éfféctué immédiatement après.
     +/
    ref Feeder next () @property {
	return this._next;
    }
    
    /++
     Remise à zéro des données de la tâche.
     +/
    void reset ();

    
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
	if (this.next.isTask) 
	    buf.writef ("%s:", this.next.serialize);
	
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
    
    private SList!Feeder _tasks;

    this () {}

    void compose (T : Task, TNext ...) (T task, TNext nexts) {
	if (!this._tasks.empty) {
	    task.next = this._tasks.front;
	}
	
	this._tasks.insertFront (Feeder (task));	
	static if (nexts.length != 0)
	    compose (nexts);		
    }
    
    Feeder run (T) (T data) {
	if (!this._tasks.empty) {
	    return this._tasks.front.run (Feeder (data));
	} else {
	    assert (false, "Run empty stream");
	}
    }

    private static Task readTask (Lexer lex) {
	import std.conv, std.stdio;
	auto ident = lex.next ();
	if (!ident.isEof) {	
	    auto num = ident.str.to!(ulong);
	    auto task = Task.__initializer__ [num].simpleClone ();
	    auto next = lex.next ();
	    if (next == Tokens.DIESE) {
		lex.next (Tokens.GPAR);
		while (true) {
		    next = lex.next ();
		    auto attr = next.str.to!(ulong);
		    lex.next (Tokens.EXL);
		    next = lex.next ();
		    num = next.str.to!(ulong);
		    auto insideTask = Task.__initializer__ [num].simpleClone ();
		    task.set (attr, insideTask);
		    next = lex.next (Tokens.DPAR, Tokens.VIRG);
		    if (next == Tokens.DPAR) break;
		}
	    } else lex.rewind ();
	    return task;
	}
	return null;
    }
    
    static Stream deserialize (string name) {
	auto lex = new StringLexer (name, [Tokens.SPACE, Tokens.RET, Tokens.RRET]);
	auto stream = new Stream;
	while (true) {
	    auto task = readTask (lex);	    
	    if (task is null) break;
	    else stream.compose (task);
	    auto next = lex.next (Tokens.DPOINT);
	    if (next.isEof) break;
	}
	return stream;
    }
    
    string serialize () {
	if (!this._tasks.empty)
	    return this._tasks.front.serialize ();
	else
	    assert (false, "Serialize empty stream");
    }
    
}
