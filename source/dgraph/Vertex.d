module dgraph.Vertex;


/++
 La classe vertex représente un sommet du graphe, il est identifié par un ID unique
 +/
class Vertex () {
    
    private ulong _id;

    this (ulong id) {
	this._id = id;
    }
    
    const (ulong) id () {
	return this._id;
    }    
}

/++
 La classe vertex représente un sommet du graphe, il est identifié par un ID unique
 Cette variante prend un type template pour stocker les propriétés du sommet
 +/
class Vertex (T) {

    /++ Cet ID doit être unique dans un graphe +/
    private ulong _id;

    /++ Les propriétés attaché au sommet +/
    private T _property;
    
    this (ulong id, T property) {
	this._id = id;
	this._property = property;
    }

    ref T property () {
	return this._property;
    }

    const(ulong) id () {
	return this._id;
    }       
    
}
