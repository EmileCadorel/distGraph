module dsl.ast.Type;
import dsl.syntax.Word;
import dsl.ast.Expression;
import dsl.semantic.InfoType;
import std.container;

class Type {

    private Word _ident;

    private Expression _len;
    
    private bool _isArray;

    private InfoType _info;

    this (string name) {
	this._ident = Word (Location.eof, name);
    }
    
    this (Word ident) {
	this._ident = ident;
    }

    void setLen (Expression len) {
	this._len = len;
	this._isArray = true;
    }

    bool isArray () {
	return this._isArray;
    }

    void isArray (bool isA) {
	this._isArray = isA;
    }
    
    Word ident () {
	return this._ident;
    }

    ref InfoType info () {
	return this._info;
    }
    
    override string toString () {
	import std.outbuffer;
	auto buf = new OutBuffer ();
	if (this._isArray)
	    buf.writef ("__global ");

	if (this._info is null) {
	    buf.writef ("%s", this._ident.toString);	
	    
	    if (this._isArray) {
		if (this._len) buf.writef ("[%s]", this._len.toString);
		else buf.writef ("* ");
	    }
	} else {
	    buf.writef ("%s", this._info.toString);
	}
	
	return buf.toString ();
    }    
}
