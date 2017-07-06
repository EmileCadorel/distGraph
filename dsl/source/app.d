import std.stdio;
import syntax.Visitor;

void main (string [] args) {
    if (args.length > 1) {
	foreach (it ; args [1 .. $]) {
	    auto visitor = new Visitor (it);
	    auto functions = visitor.visit ();
	    writeln (functions []);
	}	
    } else
	assert (false, "Usage files...");
}
