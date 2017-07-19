module ast.Cast;
import ast.Expression;
import ast.Type;
import syntax.Word;

class Cast : Expression {

    private Type _type;

    private Expression _what;
    
    this (Word ident, Type type, Expression what) {
	super (ident);
	this._type = type;
	this._what = what;
    }

    override string toString () {
	import std.format;
	return format ("cast (%s)(%s)", this._type.toString, this._what.toString);
    }

}
