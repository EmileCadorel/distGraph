module dgraph.Edge;

/++
 La classe Edge associe deux sommets d'un graphe (en fonction de leurs ID)
+/
class Edge () {
    
    /++ On est sur un graphe orienté donc, une source et une destination +/
    private ulong _src;
    private ulong _dst;
    
    this (ulong src, ulong dst) {
	this._src = src;
	this._dst = dst;
    }

    /++
     Récupération de la source de l'arête.
     On ne peut pas changer la topologie du graphe
     +/
    const (ulong) src () {
	return this._src;
    }
    
    /++
     Récupération de la déstination de l'arête.
     On ne peut pas changer la topologie du graphe
     +/
    const (ulong) dst () {
	return this._dst;
    }
    
}

/++
 La classe Edge associe deux sommets d'un graphe (en fonction de leurs ID)
 Cette variante prend un type en template pour y stocker les propriétés
+/
class Edge (T) {

    /++ On est sur un graphe orienté donc, une source et une destination +/
    private ulong _src;
    private ulong _dst;

    /++ Les informations contenu dans l'arête +/
    private T _property;

    this (ulong src, ulong dst, T property) {
	this._src = src;
	this._dst = dst;
	this._property = property;
    }

    /++
     Récupération de la source de l'arête.
     On ne peut pas changer la topologie du graphe
     +/
    const (ulong) src () {
	return this._src;
    }

    /++
     Récupération de la déstination de l'arête.
     On ne peut pas changer la topologie du graphe
     +/
    const (ulong) dst () {
	return this._dst;
    }

    /++
     Getter et Setter des propriété de l'arête
     +/
    ref T property () {
	return this._property;
    }
}
