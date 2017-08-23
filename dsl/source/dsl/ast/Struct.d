module dsl.ast.Struct;
import dsl.ast.TypedVar;
import dsl.ast.Type;
import dsl.ast.Var;
import dsl.syntax.Word;
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

    Array!TypedVar params () {
	return this._params;
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
