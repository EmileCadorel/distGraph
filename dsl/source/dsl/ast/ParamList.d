module dsl.ast.ParamList;
import dsl.ast.Expression;
import std.container;

class ParamList {

    private Array!Expression _params;

    void addParam (Expression param) {
	this._params.insertBack (param);
    }

    Array!Expression params () {
	return this._params;
    }
    
    override string toString () {
	import std.outbuffer;
	auto buf = new OutBuffer ();
	foreach (it ; this._params) {
	    buf.writef ("%s%s", it.toString, it !is this._params [$ - 1] ? ", " : "");
	}
	return buf.toString;
    }    
    
}
