module ast.ConstArray;
import ast.Expression;
import std.container;
import syntax.Word;

class ConstArray : Expression {

    private Array!Expression _params;

    this (Word ident) {
	super (ident);
    }

    void addParam (Expression param) {
	this._params.insertBack (param);
    }

    override string toString () {
	import std.outbuffer;
	auto buf = new OutBuffer ();
	buf.writef ("[");
	foreach (it ; this._params) {
	    buf.writef ("%s%s", it.toString, it !is this._params [$ - 1] ? ", " : "");
	}
	buf.writef ("]");
	return buf.toString;
    }
    

}
