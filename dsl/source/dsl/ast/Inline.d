module dsl.ast.Inline;
import dsl.syntax._;
import dsl.ast._;
import std.outbuffer, std.container;
import dsl.semantic.Table;

class Inline : Declaration {

    protected Word _begin;

    protected Word _end;
    
    protected Expression _id;

    protected Word _what;

    protected Array!Expression _templates;

    protected this () {
    }

    this (string name) {
	this._id = new Decimal (Word (Location.eof, "0"));
	this._what = Word (Location.eof, name);
	this._begin = Word.eof;
	this._end = Word.eof;
    }
    
    this (Word begin, Expression id, Word what, Word end) {
	this._id = id;
	this._what = what;
	this._begin = begin;
	this._end = end;
    }

    ref Word what () {
	return this._what;
    }

    Word begin () {
	return this._begin;
    }
    
    ref Word end () {
	return this._end;
    }
    
    void addTemplate (Expression expr) {
	this._templates.insertBack (expr);
    }
    
    Array!Expression templates () {
	return this._templates;
    }

    Expression id () {
	return this._id;
    }
    
    override string replace () {
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
