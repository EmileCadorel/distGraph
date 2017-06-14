module assign.skeleton.Stream;
public import assign.skeleton.Task;
public import assign.skeleton.Repeat;
public import assign.skeleton.Elem;
public import assign.data.Data;
import std.concurrency, std.traits;
import std.container, std.array;
import std.outbuffer, std.algorithm;
import std.stdio, rng = std.range;

package class Node {

    Task task;

    SList!Node childs;

    Node father;
    
    this (Task t) {
	this.task = t;
    }
    
}

class StreamTree {
    
    private Node _root;
    
    /++
     Met à jour la racine du flux
     Params:
     root = la nouvelle racine
     +/
    Node setRoot (Task root) {
	this._root = new Node (root);
	return this._root;
    }
    
    /++
     Ajoute un fils à la tâche father
     Params:
     father = le père de la nouvelle tâche
     child = la nouvelle tâche     
     +/
    Node addChild (Node father, Task child) {
	if (this._root is null)
	    this._root = father;

	auto node = new Node (child);
	father.childs.insertFront (node);
	node.father = father;
	return node;
    }

    /++
     Ajoute un fils à la tâche father
     Params:
     father = le père de la nouvelle tâche
     child = la nouvelle tâche     
     +/
    Node addChild (Node father, Node child) {
	if (this._root is null)
	    this._root = father;

	father.childs.insertFront (child);
	child.father = father;
	return child;
    }    

    /++
     Surcharge de l'operateur foreach
     Params:
     dg = la fonction scopé du foreach
     Returns: le retour du delegate
     +/
    int opApply (scope int delegate (Node) dg) {	
	int traverse (Node current, int delegate (Node) dg) {
	    auto res = dg (current);
	    if (res) return res;

	    foreach (it ; current.childs) {
		res = traverse (it, dg);
		if (res) return res;
	    }
	    return res;
	}
	
	if (this._root) 
	    return traverse (this._root, dg);
	return 0;
    }
    
    /++
     Transforme le graphe en string sous format .dot
     Params:
     buf = le buffer à remplir
     Returns: le buffer remplis
     +/
    OutBuffer toDot (OutBuffer buf = null) {

	void toBuf (Node current, OutBuffer edges, OutBuffer labels) {
	    labels.writefln ("\t%d [label=\"%s\"];",  typeid (current.task).toHash, typeid (current.task).toString);
	    foreach (it ; current.childs) {
		edges.writefln ("\t%d -> %d", typeid (current.task).toHash, typeid (it.task).toHash);
		toBuf (it, edges, labels);
	    }	    
	}
	
	auto labelBuf = new OutBuffer ();
	auto edgesBuf = new OutBuffer ();
	if (this._root) {
	    toBuf (this._root, edgesBuf, labelBuf);
	}
	if (buf is null) buf = new OutBuffer ();
	buf.writefln ("digraph StreamGraph {");
	buf.writefln ("%s", labelBuf.toString);
	buf.writefln ("\n%s", edgesBuf.toString);
	buf.writefln ("}");
	return buf;
    }
    
}

/++
 Classe utilisé pour définir un flux de données entre les différents squelettes.
+/
class Stream {
    
    private StreamTree _stream;

    this () {}

    /++
     Fonction utilisé pour la composition arbitraire
     Params:
     gp = le graphe de flux, qui va servir de guide à l'execution.     
     +/
    void compose (StreamTree gp) {
	this._stream = gp;
    }
    
    /++
     Composition simple (les unes après les autres (task -> nexts -> ... )).
     Params:
     task = la première tâches à inséré
     nexts = la listes des tâches suivantes.
     +/
    Node compose (T : Task, TNext ...) (T task, TNext nexts) {
	auto father = compose (nexts);
	return this._stream.addChild (father, task);
    }

    /++
     Composition simple
     Params:
     task = la tâche à inséré dans le graphe.
     +/
    Node compose (T : Task) (T task) {
	this._stream = new StreamTree ();	
	return this._stream.setRoot (task);
    }

    /++
     Composition simple (les unes après les autres, sens inverse compose ,(t <- nexts <- ...)).
     Params:
     task = la dernière tâche qui va être éffectué
     nexts = les tâches précédentes.
     +/
    Node pipe (T : Task, TNext ...) (T task, TNext nexts) {
	auto child = pipe (nexts);
	auto father = this._stream.setRoot (task);
	this._stream.addChild (father, child);
	return father;
    }


    /++
     Composition simple (les unes après les autres, sens inverse compose ,(t <- nexts <- ...)).
     Params:
     task = la tâche à insérer dans le graphe.
     +/
    Node pipe (T : Task) (T task) {
	this._stream = new StreamTree ();
	return this._stream.setRoot (task);
    }
    
    /++
     Returns: le graphe de flux généré par la composition.
     +/
    StreamTree tree () {
	return this._stream;
    }

    DistData run (T) (T data) {
	import assign.skeleton.StreamExecutor;
	return StreamExecutor.instance.execute (this, data);
    }
    
    /++
     Transforme le flux en string au format .dot
     Params:
     buf = un buffer à remplir
     Returns: le buffer execute
     +/
    OutBuffer toDot (OutBuffer buf = null) {
	if (this._stream) 
	    return this._stream.toDot (buf);
	else assert (false, "Le flux est vide");
    }

}

/++
 Squelette de réduction 
 Applique un Elem d'arité 2, jusqu'a ce qu'il ne possède plus qu'une seule case.
 Params:
 fun = la fonction d'arité 2
+/
template Reduce (alias fun) {
    alias T = ReturnType!fun;

    auto Reduce () {       
	return new Repeat!T (
	    new Elem!(fun) 	    
	);
    }
}

/++
 Applique un elem d'arité 1
 Se fait en une passe
 Params:
 fun = la fonction d'arité 1
 +/
template Map (alias fun) {
    auto Map () {
	return new Elem!(fun);	    
    }
}

/++
 Applique un IndexedElem sur une fonction d'arité 1 
 Params:
 fun = la fonction d'arité 1, qui prend en entrée un ulong.
 +/
template Generate (alias fun) {
    auto Generate () {
	return new IndexedElem!fun;	
    }    
}

