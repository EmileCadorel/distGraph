module test;
import std.stdio;
import mpiez.admin;
import utils.Options;
import std.traits;
import utils.FunctionTable;
import std.conv, std.math, std.algorithm;
import skeleton.Reduce, skeleton.Map;
import skeleton.Generate;
import dgraph.DistGraphLoader;

void master (int id, int total) {
    auto nb = 2;
    if (Options.active ("-n"))
	nb = to!(int) (Options ["-n"]);
    if (Options.active ("-l"))
	DistGraphLoader.lambda = to!float (Options ["-l"]);
    if (!Options.active ("-i"))
	assert (false, "On a besion d'un fichier d'entrée");

    auto grp = DistGraphLoader.open (Options ["-i"], nb);
    if (id == 0) {
	writeln (grp.partitions);
	auto filename = "out.dot";
	if (Options.active ("-o")) filename = Options ["-o"];
	auto file = File (filename, "w+");
	file.write (grp.toDot (null, true).toString);
	file.close ();
    }
}

int main (string [] args) {
    auto adm = new Admin!(master) (args);
    adm.finalize ();
    return 0;
}
