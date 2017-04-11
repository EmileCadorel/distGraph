module dgraph.Partition;

class Partition {

    private ulong _id;

    /++
     La taille de la partition (nombre de sommets)
     +/
    private ulong _size;    
    
    this (ulong id) {
	this._id = id;
    }

    const (ulong) id () const {
	return this._id;
    }
    
    const (ulong) length () const {
	return this._size;
    }

    const (ulong) size () const {
	return this._size;
    }
    
    ref ulong length () {
	return this._size;
    }

    ref ulong size () {
	return this._size;
    }

}
