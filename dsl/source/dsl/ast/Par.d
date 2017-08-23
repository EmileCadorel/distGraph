module dsl.ast.Par;
import dsl.ast.Expression, dsl.ast.ParamList;
import dsl.syntax.Word;
import dsl.semantic.types._;

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
	import std.format, std.outbuffer;
	if (auto cst = cast (StructCstInfo) this._left.sym.type) {
	    auto buf = new OutBuffer;
	    buf.writef ("(struct %s) { ", this._left.toString);
	    foreach (it ; 0 .. this._params.params.length) {
		auto id = cst.str.params [it].ident;
		buf.writef (".%s = %s", id.str, this._params.params [it].toString);
		if (it != this._params.params.length - 1) buf.write (", ");
	    }
	    buf.write ("}");
	    return buf.toString ();
	} else 
	    return format ("%s (%s)", this._left.toString, this._params.toString);
    }
    
}
