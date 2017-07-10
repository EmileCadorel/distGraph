module ast.Block;
import ast.Instruction, syntax.Word;
import ast.Expression;
import std.container;

class Block : Instruction {

    private Array!Instruction _insts;

    this (Word token) {
	super (token);
    }

    void addInst (Instruction inst) {
	this._insts.insertBack (inst);
    }
    
    override string toString () {
	import std.outbuffer, std.string;
	auto buf = new OutBuffer ();
	buf.writefln ("{");
	foreach (it ; this._insts) {
	    it.indent = this._indent + 4;	    
	    buf.writef ("%s%s", rightJustify ("", (this._indent + 4), ' '), it.toString);
	    if (cast (Expression) it) buf.writefln (";");
	    else buf.writefln ("");
	}	
	buf.writef ("%s}", rightJustify ("", this._indent, ' '));
	return buf.toString;
    }

}
