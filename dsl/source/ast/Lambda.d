module ast.Lambda;
import ast._;
import std.container;
import syntax.Word;

class Lambda : Expression {

    private Array!Var _params;

    private Expression _content;


    this (Word token) {
	super (token);
    }

    void addParam (Var param) {
	this._params.insertBack (param);
    }

    ref Expression content () {
	return this._content;
    }

    override string toString () {
	import std.outbuffer;
	auto buf = new OutBuffer ();
	
	buf.writef ("(");
	foreach (it ; this._params)
	    buf.writef ("%s%s", it.toString, it is this._params [$ - 1] ? "" : ", ");
	buf.writef (") => %s", this._content.toString);
	return buf.toString;
    }

}
