module dgraph.Edge;
import std.outbuffer;
import utils.Colors;
import std.traits;

/++
 La classe Edge associe deux sommets d'un graphe (en fonction de leurs ID)
 +/
class Edge {

    private ulong _src;
    private ulong _dst;

    private ulong _color;
    private bool _isOriented;
    
    this (ulong src, ulong dst) {
	this._src = src;
	this._dst = dst;
    }

    /++
     Récupération de la source de l'arête.
     On ne peut pas changer la topologie du graphe
     +/
    const (ulong) src () const {
	return this._src;
    }
    
    /++
     Récupération de la déstination de l'arête.
     On ne peut pas changer la topologie du graphe
     +/
    const (ulong) dst () const {
	return this._dst;
    }

    /++
     On retourne la couleur de l'arête.
     +/
    const (ulong) color () const {
	return this._color;
    }

    /++
     Met à jour la couleur
     +/
    ref color () {
	return this._color;
    }

    /++
     Returns: le bool qui définis si l'arête est bidirectionnelle
     +/
    ref bool isOriented () {
	return this._isOriented;
    }

    Edge reverse () const {
	auto aux = new Edge (this._dst, this._src);
	aux.color = this._color;
	return aux;
    }
    
    /++
     Ecris l'arête au format Dot dans le buffer.
     +/
    OutBuffer toDot (OutBuffer buf) {
	if (this._color != 0 && this._color < 10)
	    buf.writefln ("\t%d -> %d [color=\"/%s\"]", this._src, this._dst,
			  [EnumMembers!Color][this._color - 1].value);
	else
	    buf.writefln ("\t%d -> %d", this._src, this._dst);
	return buf;
    }
    
}
