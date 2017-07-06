module ast.Dot;
import ast.Expression;
import ast.Var;
import syntax.Word;

class Dot : Expression {

    private Expression _left;

    private Var _right;
    
    this (Word token, Expression  left, Var right) {
	super (token);
	this._left = left;
	this._right = right;
    }

    override string toString () {
	import std.format;
	return format ("%s.%s", this._left.toString, this._right.toString);
    }    

}
