module dgraph.Vertex;

class Vertex (T) {

    private ulong _id;
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
