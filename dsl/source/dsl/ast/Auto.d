module dsl.ast.Auto;
import dsl.ast.Expression, dsl.ast.Var;
import dsl.ast.Instruction;
import std.container, std.string;
import dsl.syntax.Word;

class Auto : Instruction {

    private Array!Var _var;

    private Array!Expression _expr;

    this (Word token) {
	super (token);
    }

    void addInit (Var var, Expression expr) {
	this._var.insertBack (var);
	this._expr.insertBack (expr);
    }

    Array!Expression rights () {
	return this._expr;
    }

    Array!Var vars () {
	return this._var;
    }
    
    override string toString () {
	import std.outbuffer;
	auto buf = new OutBuffer ();
	foreach (it ; 0 .. this._var.length) {
	    if (it != 0) buf.writef ("%s", rightJustify ("", this._indent, ' '));
	    buf.writef ("%s %s = %s;%s",
			this._var [it].type.toString,
			this._var [it].toString,
			this._expr [it].toString,
			it != this._var.length ? "\n" : "");	    
			
	}
	return buf.toString;
    }


}
