module assign.skeleton.Stream;
import std.container;

struct Feeder {
    
    void * a;
    void [] ax;
    Task _task;

    this (Task task) {
	this._task = task;
    }
    
    this (T : U [], U) (T a) {
	this.ax = a;
    }
    
    this (T) (T a) {
	this.a = new T (a);
    }
    
    void set (T) (T t) @nogc {
	*(cast(T*) this.a) = t;
    }
    
    T get (T) () @nogc {	
	return *(cast (T*) (this.a));
    }

    T get (T : U[], U) () @nogc {	
	return (cast (U[]) (this.ax));
    }    

    Feeder run (Feeder fed) {
	this._task.feed (fed);
	return this._task.run ();
    }
    
    bool isArray () {
	return this.ax !is null;
    }

    bool isTask () {
	return this._task !is null;
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
    abstract Feeder run ();

    /++
     Le nombre de donnée requise par la tâche
     +/
    abstract uint arity ();

    /++
     Ajoute une données dans la tâche, qu'elle devra consommé.
     Params:
     data = la données à consommer.
     +/
    abstract void feed (Feeder data);

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
