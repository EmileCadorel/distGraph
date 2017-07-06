module ast.If;
import ast.Instruction;
import ast.Expression;
import ast.Block;
import syntax.Word;

class If : Instruction {

    private Expression _test;

    private Block _block;
    
    private If _else;

    this (Word token, Expression test, Block block) {
	super (token);
	this._test = test;
	this._block = block;
    }

    void setElse (If _else) {
	this._else = _else;
    }
    
    override string toString () {
	import std.outbuffer;
	auto buf = new OutBuffer ();
	this._block.indent = this._indent;
	if (this._test !is null) {
	    buf.writef ("if (%s) %s", this._test.toString, this._block.toString ());
	} else {
	    buf.writef ("%s", this._block.toString);
	}

	if (this._else) {
	    this._else.indent = this._indent;
	    buf.writef (" else %s", this._else.toString);
	}
	return buf.toString;
    }
    
}
