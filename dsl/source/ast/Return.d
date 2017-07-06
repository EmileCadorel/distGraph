module ast.Return;
import ast.Instruction, ast.Expression;
import syntax.Word;

class Return : Instruction {

    private Expression _what;
    
    this (Word token, Expression what) {
	super (token);
	this._what = what;
    }

    override string toString () {
	import std.format;
	return format ("return %s;", this._what.toString);
    }

}
