module ast.TypedVar;
import syntax.Word;
import std.container;
import ast.Type;

class TypedVar {

    private Word _ident;

    private Type _type;

    this (Type type, Word ident) {
	this._ident = ident;
	this._type = type;
    }

    Word ident () {
	return this._ident;
    }
    
    Type type () {
	return this._type;
    }
    
    override string toString () {
	import std.format;
	return format ("%s %s", this._type.toString, this._ident.toString);	
    }       

}
