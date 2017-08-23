module dsl.ast.Dot;
import dsl.ast.Expression;
import dsl.ast.Var;
import dsl.syntax.Word;

class Dot : Expression {

    private Expression _left;

    private Var _right;
    
    this (Word token, Expression  left, Var right) {
	super (token);
	this._left = left;
	this._right = right;
    }

    Expression left () {
	return this._left;
    }

    Var right () {
	return this._right;
    }
    
    override string toString () {
	import std.format;
	return format ("%s.%s", this._left.toString, this._right.toString);
    }    

}
