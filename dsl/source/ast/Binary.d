module ast.Binary;
import ast.Binary;
import syntax.Word, ast.Expression;

class Binary : Expression {

    private Expression _left;

    private Expression _right;
        
    this (Word token, Expression left, Expression right) {
	super (token);
	this._left = left;
	this._right = right;
    }

    Expression left () {
	return this._left;
    }

    Expression right () {
	return this._right;
    }
    
    override string toString () {
	import std.format;

	return format ("(%s %s %s)", this._left.toString, this._token.toString, this._right.toString);
    }


}
