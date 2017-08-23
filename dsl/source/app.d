import std.stdio, std.string;
import std.array, std.outbuffer;
import dsl.ast.Function;
import dsl.syntax.Visitor, dsl.semantic.Table;
import sem = dsl.semantic.Visitor;
import std.json, std.algorithm;
import std.file, std.path, std.process;

void declare (string name) {
    auto file = File (name, "r");
    auto buf = new OutBuffer ();
    auto prog = new Visitor (name).visit ();

    // Déclaration de toute les informations récupéré par l'analyse syntaxique dans la table des symboles    
    sem.declare (prog);
}

void targetTime  () {
    // On valide toutes les fonctions
    sem.validate ();

    foreach (prog ; TABLE.allPrograms) {
	sem.replace (prog.file, prog);
    }
    
    // On commence par valider tout ce qui à été déclaré
    mkdirRecurse (TABLE.outdir);
    toFile (sem.target (), TABLE.outFile);
    toFile (cast (string) read ("dub.json"), "out/dub.json");    
}

string readDub () {
    auto json = parseJSON (cast (string) read ("dub.json"));
    auto src = "sourcePaths" in json;
    string dir;
    if (src is null) dir = "source";
    else dir = src.str;

    foreach (string name ; dirEntries (dir, SpanMode.depth)
	     .filter! (f => f.name.endsWith (".d"))) {
	declare (name);
    }

    rmdirRecurse ("./out/");
    mkdir ("./out/");
    targetTime ();
    if (auto exec = "name" in json) {
	return exec.str;
    } else return "a.out";
}

void generateSolution (string exec) {
    chdir ("./out/");
    auto cmd = execute (["dub", "build"]);
    writeln (cmd.output);
    chdir ("..");
    copy (buildPath ("out/", exec), exec, Yes.preserveAttributes);    
}


void main () {    
    string exec = readDub ();
    generateSolution (exec);
}
