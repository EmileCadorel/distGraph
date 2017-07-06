module ast.TypedVar;
import syntax.Word;
import std.container;

class Type {

    private Word _ident;

    private Array!Type _templates;

    this (Word ident) {
	this._ident = ident;
    }

    void addTemplate (Type type) {
	this._templates.insertBack (type);
    }    

    override string toString () {
	import std.outbuffer;
	auto buf = new OutBuffer ();
	buf.writef ("%s", this._ident.toString);
	if (this._templates.length != 0) {
	    buf.writef ("!(");
	    foreach (it ; this._templates) {
		buf.writef ("%s%s", it.toString, it !is this._templates[$ - 1] ? ", " : "");
	    }
	    buf.writef (")");
	}
	return buf.toString ();
    }    
}

class TypedVar {

    private Word _ident;

    private Type _type;

    this (Type type, Word ident) {
	this._ident = ident;
	this._type = type;
    }
    
    override string toString () {
	import std.format;
	return format ("%s %s", this._type.toString, this._ident.toString);	
    }       

}
