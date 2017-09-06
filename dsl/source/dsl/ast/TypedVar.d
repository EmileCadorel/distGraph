module dsl.ast.TypedVar;
import dsl.syntax.Word;
import std.container;
import dsl.ast.Type;
import dsl.semantic.Symbol;

class TypedVar {

    private Word _ident;

    private Type _type;

    private bool _isLocal;
    
    this (Type type, Word ident, bool isLocal) {
	this._ident = ident;
	this._type = type;
	this._isLocal = isLocal;
    }

    Word ident () {
	return this._ident;
    }
    
    Type type () {
	return this._type;
    }

    bool isLocal () {
	return this._isLocal;
    }    
    
    string initString () {
	import std.format;	
	this._type.isLocal = this._isLocal;
	return format ("%s %s", this._type.initString, this._ident.toString);
    }
    
    override string toString () {
	import std.format;
	this._type.isLocal = this._isLocal;
	return format ("%s %s", this._type.toString, this._ident.toString);
    }       

}
