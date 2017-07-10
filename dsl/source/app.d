import std.stdio, std.string;
import std.array, std.outbuffer;
import ast.Function;
import syntax.Visitor;

string generateD (string name) {
    auto file = File (name, "r");
    auto buf = new OutBuffer ();
    auto functions = new Visitor (name).visit ().array ();
    auto current = 1;
    while (true) {
	auto ln = file.readln ();
	if (ln is null) break;
	if (functions.length != 0 && functions [0].begin.locus.line == current) {
	    auto beg = ln [0 .. functions [0].begin.locus.column - 1];
	    if (beg.strip.length != 0)
		buf.writefln (beg);
	    buf.writef ("\"%s\"", functions [0].toString ());
	    foreach (it ; functions [0].begin.locus.line .. functions [0].end.locus.line - 1)
		ln = file.readln ();

	    auto end = ln [functions [0].end.locus.column - 1.. $];
	    buf.writef (end);
	    functions = functions [1 .. $];
	} else {
	    buf.writef (ln);
	}
	current ++;
    }
    return buf.toString ();
}

void mkdirGen (string dir) {
    import std.file, std.algorithm, std.string, std.path;
    foreach (DirEntry fl ; dirEntries (dir, SpanMode.depth).
	     filter!(f => f.name.endsWith (".d"))) {
	
	mkdirRecurse (buildPath ("out", fl.name [0 .. fl.name.lastIndexOf ('/')]));
	auto flContent = generateD (fl.name);
	toFile (flContent, buildPath ("out", fl.name));
    }
}

void main (string [] args) {
    if (args.length > 1) {
	/*	foreach (it ; args [1 .. $]) {
	    auto visitor = new Visitor (it);
	    auto functions = visitor.visit ();
	    writeln (functions []);
	    toFile (generateD (it, functions.array), "out.d");
	    }*/
	mkdirGen (args [1]);	
    } else
	assert (false, "Usage files...");
}
