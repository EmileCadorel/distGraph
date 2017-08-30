module dsl.ast.GlobLambda;
import dsl.ast._;
import dsl.syntax._;
import std.outbuffer, std.container;


class GlobLambda : Declaration {

    protected Word _begin;

    protected Word _end;

    protected Array!Var _vars;

    protected Block _block;

    protected Expression _expression;


    this (Word begin) {
	this._begin = begin;
    }

    Word begin () {
	return this._begin;
    }
    
    ref Word end () {
	return this._end;
    }

    ref Array!Var vars () {
	return this._vars;
    }

    ref Block block () {
	return this._block;
    }

    ref Expression expression () {
	return this._expression;
    }
        
    override string replace () {
	auto lmbd = new OutBuffer ();
	lmbd.write ("(");
	foreach (it ; this._vars)
	    lmbd.writef ("%s%s", it.toString, it is this._vars [$ - 1] ? "" : ", "); 

	lmbd.writef (")");
	if (this._block) {
	    lmbd.writef ("{\n%s\n}", this._block.toString);
	} else {
	    lmbd.writef ("=> %s\n", this._expression.toString);
	}
	
	auto buf = new OutBuffer ();	
	buf.writefln ("Lambda!(%s, \"%s\")",
		     lmbd.toString,
		     lmbd.toString);
	return buf.toString;
    }

}
