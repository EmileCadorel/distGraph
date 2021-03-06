module dsl.ast.For;
import dsl.ast.Instruction;
import dsl.ast.Expression;
import dsl.ast.Block;
import std.container;
import dsl.syntax.Word;

class For : Instruction {

    private Instruction _begin;

    private Expression _test;

    private Array!Expression _iter;

    private Block _block;
    
    this (Word token) {
	super (token);
    }

    Instruction begin () {
	return this._begin;
    }

    Expression test () {
	return this._test;
    }

    Array!Expression iter () {
	return this._iter;
    }

    Block block () {
	return this._block;
    }
    
    void setBegin (Instruction begin) {
	this._begin = begin;
    }

    void setTest (Expression test) {
	this._test = test;
    }

    void addIter (Expression iter) {
	this._iter.insertBack (iter);
    }

    void setBlock (Block block) {
	this._block = block;
    }

    override string toString () {
	import std.outbuffer;
	auto buf = new OutBuffer ();
	buf.writef ("for (");
	if (this._begin) {
	    auto ln = this._begin.toString;
	    if (ln [$ - 1] == '\n') ln = ln [0 .. $ - 1];
	    buf.writef ("%s", ln);
	    if (cast (Expression) this._begin) buf.writef (" ;");
	} else buf.writef (";");

	if (this._test) buf.writef (" %s", this._test);
	buf.writef (" ; ");

	foreach (it ; this._iter) {
	    buf.writef ("%s%s", it.toString, it !is this._iter [$ - 1] ? ", " : "");
	}

	this._block.indent = this._indent;	
	buf.writef (") %s", this._block.toString);
	return buf.toString;
    }
    
}

