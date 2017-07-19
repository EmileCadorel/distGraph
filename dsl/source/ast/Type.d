module ast.Type;
import syntax.Word;
import ast.Expression;
import std.container;

class Type {

    private Word _ident;

    private Expression _len;
    
    private bool _isArray;
    
    this (Word ident) {
	this._ident = ident;
    }

    void setLen (Expression len) {
	this._len = len;
	this._isArray = true;
    }

    ref bool isArray () {
	return this._isArray;
    }

    Word ident () {
	return this._ident;
    }
    
    override string toString () {
	import std.outbuffer;
	auto buf = new OutBuffer ();
	if (this._isArray)
	    buf.writef ("__global ");
	
	buf.writef ("%s", this._ident.toString);
	
	if (this._isArray) {
	    if (this._len) buf.writef ("[%s]", this._len.toString);
	    else buf.writef ("* ");
	}
	
	return buf.toString ();
    }    
}
