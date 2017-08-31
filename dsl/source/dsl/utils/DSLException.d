module dsl.utils.DSLException;
import dsl.syntax.Word, std.stdio, std.typecons;
import std.outbuffer, std.string;

/**
 Le tuple Color est definis par une chaine
 */
alias Color = Tuple!(string, "value");

/**
 L'enumeration des couleurs disponible 
 */
enum Colors : Color {
    RESET = Color ("\u001B[0m"),
    PURPLE = Color ("\u001B[1;35m"),
    BLUE = Color ("\u001B[1;36m"),
    YELLOW = Color ("\u001B[1;33m"),
    RED = Color ("\u001B[1;31m"),
    GREEN = Color ("\u001B[1;32m"),
    BOLD = Color ("\u001B[1;50m")
}

/**
 Exception qui informe que des erreurs sont survenus.
 */
class ErrorOccurs : Exception {

    /**
     Params:
     nb = le nombre d'erreurs
     */
    this (ulong nb) {
	super ("");
	OutBuffer buf = new OutBuffer;
	buf.writefln ("%sErreur%s: %d", Colors.RED.value, Colors.RESET.value, nb);
	msg = buf.toString ();
	this._nbError = nb;
    }

    /**
     Affiche le message d'erreur
     */
    void print () {
	writeln (this.msg);
    }

    /**
     Returns le nombre d'erreur
     */
    ref ulong nbError () {
	return this._nbError;
    }

    /// Le nombre d'erreur
    private ulong _nbError;
    
}

/**
 Ancêtre des erreurs de compilation.
*/
class DSLException : Exception {       
 
    this () {
	super ("");
    }

    /**
     Params:
     msg = Le message de l'erreur
     */
    this (string msg) {
	super (msg);
	this.msg = msg;
    }

    /**
     Params:
     locus = l'emplacement de la ligne
     Returns retourne la ligne x d'un fichier
     */
    private string getLine (Location locus) {
	import std.path, std.string;
	if (locus.file != "mixin") {
	    auto file = File (locus.file, "r");
	    string cline = null;
	    foreach (it ; 0 .. locus.line)
		cline = file.readln ();
	    return cline;
	} else {
	    import std.stdio;
	    auto lines = locus.mixLines.splitLines ();
	    return lines [locus.line - 1];
	}
    }

    /**
     Ajoute une ligne dans un buffer avec l'erreur en Jaune.
     Params:
     buf = le buffer a remplir
     locus = l'emplacement
     */
    void addLine (ref OutBuffer buf, Location locus) {
	auto line = getLine (locus);
	if (line.length > 0) {
	    auto j = 0;
	    auto leftLine = center (format ("%d", locus.line), 3, ' ');
	    auto padd = center ("", leftLine.length, ' ');
	    buf.writefln ("%s  --> %s:(%d,%d)%s\n%s%s | %s", Colors.BOLD.value, locus.file, locus.line, locus.column, Colors.RESET.value,
			  Colors.BOLD.value,
			  padd,
			  Colors.RESET.value			  
	    );
	    
	    buf.writef ("%s%s | %s%s%s%s%s%s",
			Colors.BOLD.value,
			leftLine, 
			Colors.RESET.value,
			line[0 .. locus.column - 1],
			Colors.YELLOW.value,
			line[locus.column - 1 .. locus.column + locus.length - 1],
			Colors.RESET.value,
			line[locus.column + locus.length - 1 .. $]);
	    if (line[$-1] != '\n') buf.write ("\n");
	    buf.writef ("%s%s | %s", Colors.BOLD.value, padd, Colors.RESET.value);
	    foreach (it ; 0 .. locus.column - 1) {
		if (line[it] == '\t') buf.write ('\t');
		else buf.write (' ');
	    }
	    buf.writefln ("%s", rightJustify ("", locus.length, '^'));
	} else {
	    buf.writeln ("Fin de fichier inattendue");
	}
    } 


    /**
     Ajoute une ligne dans un buffer avec l'erreur en Jaune.
     Params:
     buf = le buffer a remplir
     locus = le debut de l'emplacement
     locus2 = le deuxième emplacement
     */
    protected void addLine (ref OutBuffer buf, Location locus, Location locus2) {
	auto line = getLine (locus);
	if (line.length > 0) {
	    auto j = 0;
	    auto leftLine = center (format ("%d", locus.line), 3, ' ');
	    auto padd = center ("", leftLine.length, ' ');
	    buf.writefln ("%s  --> %s:(%d,%d)%s\n%s%s | %s", Colors.BOLD.value, locus.file, locus.line, locus.column, Colors.RESET.value,
			  Colors.BOLD.value,
			  padd, 
			  Colors.RESET.value			  
	    );
	    
	    buf.writef ("%s%s | %s%s%s%s%s%s%s%s%s%s",
			Colors.BOLD.value,
			leftLine,
			Colors.RESET.value,
			line[0 .. locus.column - 1],
			Colors.YELLOW.value,
			line[locus.column - 1 .. locus.column + locus.length - 1],
			Colors.RESET.value,
			line [locus.column + locus.length - 1 .. locus2.column - 1],
			Colors.YELLOW.value,
			line [locus2.column - 1 .. locus2.column + locus2.length - 1],
			Colors.RESET.value,
			line [locus2.column + locus2.length - 1 .. $]);
	    
	    if (line[$-1] != '\n') buf.write ("\n");
	    buf.writef ("%s%s | %s", Colors.BOLD.value, padd, Colors.RESET.value);
	    foreach (it ; 0 .. locus.column - 1) {
		if (line[it] == '\t') buf.write ('\t');
		else buf.write (' ');
	    }
	    buf.writef ("%s", rightJustify ("", locus.length, '^'));
	    foreach (it ; locus.column + locus.length - 1 .. locus2.column - 1) {
		if (line[it] == '\t') buf.write ('\t');
		else buf.write (' ');
	    }
	    buf.writefln ("%s", rightJustify ("", locus2.length, '^'));
	} else {
	    buf.writeln ("Fin de fichier inattendue");
	}
    } 

    /**
     Ajoute une ligne dans un buffer avec l'erreur en Jaune.
     Params:
     buf = le buffer a remplir
     locus = le debut de l'emplacement
     index = le decalage par rapport à l'emplacement
     lenght = la longueur de l'erreur
     */
    void addLine (ref OutBuffer buf, Location locus, ulong index, ulong length) {
	auto line = getLine (locus);
	if (line.length > 0) {
	    auto j = 0;
	    auto leftLine = center (format ("%d", locus.line), 3, ' ');
	    auto padd = center ("", leftLine.length, ' ');
	    buf.writefln ("%s  --> %s:(%d,%d)%s\n%s%s | %s", Colors.BOLD.value, locus.file, locus.line, locus.column, Colors.RESET.value,
			  Colors.BOLD.value,
			  padd, 
			  Colors.RESET.value			  
	    );
	    
	    buf.writef ("%s%s | %s%s%s%s%s%s",
			Colors.BOLD.value,
			leftLine, 
			Colors.RESET.value,
			line[0 .. locus.column + index],
			Colors.YELLOW.value,
			line[locus.column + index .. locus.column + index + length],
			Colors.RESET.value,
			line[locus.column + index + length .. $]);
	    if (line[$-1] != '\n') buf.write ("\n");
	    buf.writef ("%s%s | %s", Colors.BOLD.value, padd, Colors.RESET.value);
	    foreach (it ; 0 .. locus.column + index) {
		if (line[it] == '\t') buf.write ('\t');
		else buf.write (' ');
	    }
	    buf.writefln ("%s", rightJustify ("", length, '^'));
	} else {
	    buf.writeln ("Fin de fichier inattendue");
	}
    } 

    /**
     Affiche le message d'erreur
     */
    void print () {
	writeln (this.msg);
    }
    

}
