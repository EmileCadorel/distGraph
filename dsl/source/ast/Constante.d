module ast.Constante;
import ast.Expression;
import syntax.Word;

class Decimal : Expression {

    this (Word ident) {
	super (ident);
    }

    override string toString () {
	return this._token.toString;
    }    
}

class Float : Expression {

    private string _suite;
    
    this (Word ident, string suite) {
	super (ident);
	this._suite = suite;
    }

    this (Word ident) {
	super (ident);
	this._suite = null;
    }
    
    override string toString () {
	import std.format;
	if (this._suite !is null)
	    return format ("%s.%s", this._token.toString, this._suite);
	else
	    return format (".%s", this._token.toString);
    }
    
}


class Char : Expression {

    private ubyte _value;
    
    this (Word ident, ubyte value) {
	super (ident);
	this._value = value;
    }

    override string toString () {
	import std.format;
	return format ("\"%c\"(%d)", this._value, this._token.locus.line);
    }    
}

class String : Expression  {

    private string _value;
    
    this (Word ident, string value) {
	super (ident);
	this._value = value;
    }

    override string toString () {
	import std.format;
	return format ("\"%s\"(%d)", this._value, this._token.locus.line);
    }    
}


class Bool : Expression {
    
    this (Word tok) {
	super (tok);
    }

    override string toString () {
	return this._token.toString ();
    }    
    
}

class Null : Expression {
    this (Word tok) {
	super (tok);
    }

    override string toString () {
	return this._token.toString ();
    }    
}


