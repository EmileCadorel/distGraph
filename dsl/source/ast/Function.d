module ast.Function;
import ast.TypedVar;
import std.container;
import syntax.Word, ast.Block;
import ast.Instruction;

class Function {

    private Word _begin, _end;
    
    private Array!TypedVar _params;

    private Instruction _block;

    this (Word begin) {
	this._begin = begin;
    }
    
    void addParam (TypedVar var) {
	this._params.insertBack (var);
    }

    void setBlock (Instruction block) {
	this._block = block;
    }

    void setEnd (Word end) {
	this._end = end;
    }
    
    Word begin () {
	return this._begin;
    }

    Word end () {
	return this._end;
    }
    
    override string toString () {
	import std.outbuffer, std.string;
	auto buf = new OutBuffer ();
	buf.writef ("%s(", rightJustify ("", this._begin.locus.column, ' '));
	foreach (it ; this._params) {
	    buf.writef ("%s%s", it.toString (),
			it !is this._params [$ - 1] ? ", " : "");
	}
	buf.writef (") ");
	this._block.indent = cast(uint) this._begin.locus.column;
	
	if (cast (Block) this._block) {	    
	    buf.writef (this._block.toString);
	} else {
	    buf.writefln ("{\n\treturn %s;\n}", this._block.toString);
	}
	return buf.toString;
    }
    
}
