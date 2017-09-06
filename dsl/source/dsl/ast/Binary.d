module dsl.ast.Binary;
import dsl.ast.Binary;
import dsl.syntax.Word, dsl.ast.Expression;

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
	auto lString = this._left.toString;
	auto rString = this._right.toString;
	if (cast (Binary) this._left) lString = format ("(%s)", lString);
	if (cast (Binary) this._right) rString = format ("(%s)", rString);
	
	return format ("%s %s %s", lString, this._token.toString, rString);
    }


}
