module syntax.SyntaxError;
import syntax.Word;
import utils.DSLException;
import syntax.Tokens;
import std.outbuffer, utils.Singleton;
import std.file, std.stdio, std.conv;
import std.stdio;

class SyntaxError : DSLException {
    
    private Word _sym;
    
    this (Word word) {
	OutBuffer buf = new OutBuffer();
	buf.write (Colors.RED.value);
	buf.write ("Erreur de syntaxe " ~ Colors.RESET.value ~ ":");
	buf.write (word.locus.file);
	buf.write (":(" ~ to!string(word.locus.line) ~ ", " ~ to!string(word.locus.column) ~ ") : ");
	buf.write ("'" ~ word.str ~ "'\n");
	if (word.isEof ()) {
	    buf.write ("Fin de fichier inattendue\n");
	} else if (word.locus.file != "") {
	    super.addLine (buf, word.locus);
	}
	msg = buf.toString();
	this._sym = word;
    }

    this (Word word, string [] expected) {
	OutBuffer buf = new OutBuffer();
	buf.write (Colors.RED.value);
	buf.write ("Erreur de syntaxe " ~ Colors.RESET.value ~ ":");
	buf.write (word.locus.file);
	buf.write (":(" ~ to!string(word.locus.line) ~ ", " ~ to!string(word.locus.column) ~ ") : ");
	buf.write ("'" ~ word.str ~ "' obtenue quand {");
	foreach (i ; 0 .. expected.length) {
	    buf.write ("'" ~ expected[i] ~ "'");
	    if (i < expected.length - 1) {
		buf.write (",");
	    }
	}
	buf.write ("} sont attendus \n");
	if (word.isEof ()) {
	    buf.write ("Fin de fichier inattendue\n");
	} else if (word.locus.file != "") {
	    super.addLine (buf, word.locus);
	}
	msg = buf.toString();
	this._sym = word;
    }

    this (string ancMsg, string mixinExp) {
	OutBuffer buf = new OutBuffer();
	buf.writefln ("%s\nDans l'expression mixin : %s", ancMsg, mixinExp);
	msg = buf.toString();
    }    
}
