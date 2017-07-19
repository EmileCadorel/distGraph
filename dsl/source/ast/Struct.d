module ast.Struct;
import ast.TypedVar;
import ast.Type;
import ast.Var;
import syntax.Word;
import std.container;

class Struct {

    private Array!TypedVar _params;

    private Word _ident;
    
    this (Word ident) {
	this._ident = ident;
    }

    Word ident () {
	return this._ident;
    }
    
    void addVar (TypedVar var) {
	this._params.insertBack (var);
    }    

    override string toString () {
	import std.outbuffer;
	auto buf = new OutBuffer ();
	buf.writefln ("struct %s {", this._ident);
	foreach (it ; this._params) {
	    buf.writefln ("\t%s;", it);
	}
	buf.writefln ("};");
	return buf.toString;
    }

    
}
