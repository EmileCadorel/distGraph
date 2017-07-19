module ast.Inline;
import syntax._;
import ast.Expression;
import std.outbuffer;
import semantic.Table;

class Inline {

    private Word _begin;

    private Word _end;
    
    private Expression _id;

    private Word _what;

    this (Word begin, Expression id, Word what, Word end) {
	this._id = id;
	this._what = what;
	this._begin = begin;
	this._end = end;
    }

    Word what () {
	return this._what;
    }

    Word begin () {
	return this._begin;
    }
    
    Word end () {
	return this._end;
    }
    
    Expression id () {
	return this._id;
    }
    
    string replace () {
	auto buf = new OutBuffer ();
	buf.writefln (q{new Kernel (
	    CLContext.instance.devices [%s],
	    cast(string) read("%s"),
	    "%s")
	    },
	    this._id.toString,
	    TABLE.outFile,
	this._what.str);	    
	return buf.toString ();
    }
        
}
