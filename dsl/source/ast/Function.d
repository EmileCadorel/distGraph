module ast.Function;
import ast.TypedVar;
import std.container;
import syntax.Word, ast.Block;
import ast.Instruction;

class Function {

    private Word _begin, _end;

    private Word _ident;
    
    private Array!TypedVar _params;

    private Block _block;

    this (Word begin, Word ident) {
	this._begin = begin;
	this._ident = ident;
    }
    
    void addParam (TypedVar var) {
	this._params.insertBack (var);
    }

    void setBlock (Block block) {
	this._block = block;
    }

    Block block () {
	return this._block;
    }
    
    void setEnd (Word end) {
	this._end = end;
    }

    Word begin () {
	return this._begin;
    }
    
    ref Word ident () {
	return this._ident;
    }

    Word end () {
	return this._end;
    }

    Array!TypedVar params () {
	return this._params;
    }
    
    void setParams (Array!TypedVar params) {
	this._params = params;
    }

    override string toString () {
	import std.outbuffer, std.string;
	auto buf = new OutBuffer ();
	buf.writef ("__kernel void %s (", this._ident); 
	foreach (it ; this._params) {
	    buf.writef ("%s%s", it.toString (),
			it !is this._params [$ - 1] ? ", " : "");
	}
	buf.writef (") ");
	this._block.indent = 0;
	
	if (cast (Block) this._block) {	    
	    buf.writef (this._block.toString);
	} else {
	    buf.writefln ("{\n\treturn %s;\n}", this._block.toString);
	}
	return buf.toString;
    }
    
}
