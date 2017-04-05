module dgraph.Edge;

class Edge (T) {

    private ulong _src;
    private ulong _dst;
    private T _property;

    this (ulong src, ulong dst, T property) {
	this._src = src;
	this._dst = dst;
	this._property = property;
    }
    
    const (ulong) src () {
	return this._src;
    }

    const (ulong) dst () {
	return this._dst;
    }

    ref T property () {
	return this._property;
    }
    
}
