module ast.Unary;
import ast.Expression;
import syntax.Word;

class BefUnary : Expression {

    private Expression _what;

    this (Word token, Expression what) {
	super (token);
	this._what = what;
    }

    override string toString () {
	import std.format;
	return format ("%s(%s)", this._token.toString, this._what.toString);
    }

}

class AfUnary : Expression {

    private Expression _what;

    this (Word token, Expression what) {
	super (token);
	this._what = what;
    }

    override string toString () {
	import std.format;
	return format ("(%s)%s", this._what.toString, this._token.toString);
    }
}
