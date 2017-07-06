module ast.While;
import ast.Instruction;
import ast.Expression, ast.Block;
import syntax.Word;


class While : Instruction {

    private Expression _test;

    private Block _block;

    this (Word token) {
	super (token);
    }

    void setTest (Expression test) {
	this._test = test;
    }

    void setBlock (Block block) {
	this._block = block;
    }

    override string toString () {
	import std.format;
	this._block.indent = this._indent;
	return format ("while (%s) %s", this._test.toString, this._block.toString);
    }
}
