module dsl.ast.PreInline;
import dsl.syntax._;
import dsl.ast.Expression;
import std.outbuffer, std.container;
import dsl.semantic.Table;
import dsl.ast.Inline;

class PreInline : Inline {

    this (Word begin, Word what, Word end) {
	this._begin = begin;
	this._what = what;
	this._end = end;
    }

    override string replace () {
	auto buf = new OutBuffer ();
	buf.writefln (q{new PreKernel (
	    
	)
		    },
	    TABLE.outFile ~ what.str,
	    this._what.str
	);
	return buf.toString ();
    }
        
}
