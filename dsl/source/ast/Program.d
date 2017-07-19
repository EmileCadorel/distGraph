module ast.Program;
import ast.Function, ast.Struct;
import ast.Inline;
import std.container;
import std.outbuffer, std.stdio;
import std.string;

class Program {

    private Array!Function _functions;

    private Array!Struct _structs;

    private Array!Inline _inlines;

    private string _file;
    
    this (string file, Array!Function funcs, Array!Struct str, Array!Inline inlines) {
	this._file = file;
	this._functions = funcs;
	this._structs = str;
	this._inlines = inlines;
    }

    Array!Function funcs () {
	return this._functions;
    }

    Array!Struct strs () {
	return this._structs;
    }

    Array!Inline inlines () {
	return this._inlines;
    }

    string replace () {
	auto file = File (this._file, "r");
	auto buf = new OutBuffer ();	
	auto current = 1, ln2 = 0;
	while (true) {
	    auto ln = file.readln ();
	    bool willWrite = true;
	    if (ln.strip.length != 0) ln2 ++;
	    if (ln2 == 2) {
		buf.writefln ("import system.Kernel, system.CLContext, data.Vector;");
		buf.writefln ("import std.file, std.stdio;");
	    }
	    
	    if (ln is null) break;
	    foreach (it ; this._functions) {
		if (it.begin.locus.line == current) {
		    auto beg = ln [0 .. it.begin.locus.column - 1];
		    if (beg.strip.length != 0) buf.writefln (beg);		    
		    foreach (_it ; it.begin.locus.line .. it.end.locus.line - 1) {
			ln = file.readln ();
			current ++;
		    }
		    auto end = ln [it.end.locus.column - 1 .. $];
		    buf.writef (end);
		    willWrite = false;
		    break;
		}				
	    }
	    foreach (it ; this._inlines) {
		if (it.begin.locus.line == current) {
		    auto beg = ln [0 .. it.begin.locus.column - 1];
		    if (beg.strip.length != 0) buf.writef (beg);
		    foreach (_it ; it.begin.locus.line .. it.end.locus.line - 1) {
			ln = file.readln ();
			current ++;
		    }
		    auto end = ln [(it.end.locus.column + it.end.locus.length - 1) .. $];
		    buf.writef ("%s%s", it.replace, end);
		    willWrite = false;
		    break;
		}
	    }
	    
	    if (willWrite) buf.writef (ln);
	    current ++;
	}
	return buf.toString ();
    }
    
    override string toString () {
	auto buf = new OutBuffer ();
	foreach (it ; this._structs) {
	    buf.writefln ("%s", it.toString);
	}
	buf.writefln ("");
	foreach (it ; this._functions) {
	    buf.writefln ("%s", it.toString);
	}
	return buf.toString;
    }
    

}
