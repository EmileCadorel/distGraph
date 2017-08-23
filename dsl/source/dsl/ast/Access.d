module dsl.ast.Access;
import dsl.ast.Expression, dsl.ast.ParamList;
import dsl.syntax.Word;

class Access : Expression {

    private Expression _left;

    private Expression _params;

    private Word _end;

    this (Word begin, Word end, Expression left, ParamList params) {
	super (begin);
	this._end = end;
	this._left = left;
	this._params = params.params [0];
    }

    this (Word begin, Word end, Expression left, Expression right) {
	super (begin);
	this._end = end;
	this._left = left;
	this._params = right;
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

    Expression right () {
	return this._params;
    }
        
    override string toString () {
	import std.format;
	return format ("%s [%s]", this._left.toString, this._params.toString);
    }

}
