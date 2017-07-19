import std.stdio, std.string;
import std.array, std.outbuffer;
import ast.Function;
import syntax.Visitor, semantic.Table;
import sem = semantic.Visitor;


void declare (string name) {
    auto file = File (name, "r");
    auto buf = new OutBuffer ();
    auto prog = new Visitor (name).visit ();

    // Déclaration de toute les informations récupéré par l'analyse syntaxique dans la table des symboles    
    sem.declare (prog);
    sem.replace (name, prog);
}

void targetTime  () {
    // On valide toutes les fonctions
    sem.validate ();
    
    // On commence par valider tout ce qui à été déclaré
    toFile (sem.target (), TABLE.outFile);

    toFile (q{
	    {
		"name" : "soluce",
		"targetType" : "executable",
		"dependencies" : {
		    "dopencl" : "*"
		},
		"sourcePaths" : ["./out/"]
	    }
	},
	"dub.json"
    );    
}


void main (string [] args) {
    if (args.length > 1) {
	foreach (it ; args [1..$])
	    declare (it);

	targetTime ();	
    } else
	assert (false, "Usage files...");
}
