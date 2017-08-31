module dsl.ast.TypedVar;
import dsl.syntax.Word;
import std.container;
import dsl.ast.Type;
import dsl.semantic.Symbol;

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

    string initString () {
	import std.format;	
	return format ("%s %s", this._type.initString, this._ident.toString);	
    }
    
    override string toString () {
	import std.format;	
	return format ("%s %s", this._type.toString, this._ident.toString);	
    }       

}
