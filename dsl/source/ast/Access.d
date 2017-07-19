module ast.Access;
import ast.Expression, ast.ParamList;
import syntax.Word;

class Access : Expression {

    private Expression _left;

    private ParamList _params;

    private Word _end;

    this (Word begin, Word end, Expression left, ParamList params) {
	super (begin);
	this._end = end;
	this._left = left;
	this._params = params;
    }

    Expression left () {
	return this._left;
    }

    Expression right () {
	return this._params.params [0];
    }
        
    override string toString () {
	import std.format;
	return format ("%s [%s]", this._left.toString, this._params.toString);
    }

}
