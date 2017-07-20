module ast.Par;
import ast.Expression, ast.ParamList;
import syntax.Word;

class Par : Expression {

    private Expression _left;
    
    private ParamList _params;

    private Word _end;
    
    this (Word begin, Word end, Expression left, ParamList params) {
	super (begin);
	this._end = end;
	this._left = left;
	this._params = params;
    }

    Word begin () {
	return this._token;
    }

    Word end () {
	return this._end;
    }
    
    Expression left () {
	return this._left;
    }

    ParamList params () {
	return this._params;
    }
    
    override string toString () {
	import std.format;
	return format ("%s (%s)", this._left.toString, this._params.toString);
    }
    
}
