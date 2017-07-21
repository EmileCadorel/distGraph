module ast.Skeleton;
import ast.TypedVar;
import std.container;
import syntax.Word, ast.Block;
import ast._;

class Skeleton {

    private Word _begin, _end;

    private Word _ident;

    private Array!TypedVar _params;

    private Array!Var _template;

    private Array!Word _fnNames;
    
    private Block _block;

    private ulong _nbCreated;
    
    this (Word begin, Word ident) {
	this._begin = begin;
	this._ident = ident;
    }

    Word ident () {
	return this._ident;
    }
    
    void addFnName (Word name) {
	this._fnNames.insertBack (name);
    }
    
    void addTemplate (Var tmp) {
	this._template.insertBack (tmp);
    }
    
    void addParam (TypedVar var) {
	this._params.insertBack (var);
    }

    ref Block block () {
	return this._block;
    }

    Word begin () {
	return this._begin;
    }

    ref Word end () {
	return this._end;
    }

    Array!TypedVar params () {
	return this._params;
    }

    Array!Var templates () {
	return this._template;
    }

    Array!Word fnNames () {
	return this._fnNames;
    }

    ref ulong nbCreated () {
	return this._nbCreated;
    }
    
    override string toString () {
	import std.outbuffer, std.string;
	auto buf = new OutBuffer;
	buf.writef ("__skel void %s (", this._ident);
	foreach (it ; this._params) {
	    buf.writef ("%s%s", it.toString,
			it !is this._params [$ - 1] ? ", " : "");
	}
	buf.writef (")");
	this._block.indent = 0;
	buf.writef ("%s", this._block);
	return buf.toString;
    }
    
}
