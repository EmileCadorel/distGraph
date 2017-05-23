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
    
}


/++
 Tache élémentaire qui va permettre de renseigner le flux de données.
+/
class Task {

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

    /++
     Crée un clone de la tâche
     Returns: le clone
     +/
    Task clone ();
    
}

/++
 Classe utilisé pour définir un flux de données entre les différents squelettes.
+/
class Stream {

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
    
}
