import std.stdio;
import mpiez.admin;
import utils.Options;
import std.conv, std.random;
import std.datetime;

T reduce (alias fun, T) (T [] array) {
    if (array.length > 0) {
	T total = array [0];
	foreach (it ; 1 .. array.length) {
	    total = fun (total, array [it]);
	}
	return total;
    } return T.init;
}

T parallelReduce (alias fun, T : U [], U) (int total, T  array, int len) {
    int [] o;
    scatter (0, len, array, o, MPI_COMM_WORLD);
    
    auto res = reduce!fun (o);
    int [] aux;
    gather (0, total, res, aux, MPI_COMM_WORLD);
    return aux;
}

void foo (int id, int total) {
    auto begin = Clock.currTime;
    int [] array;
    auto len = to!int (Options ["-l"]);
    if (id == 0) {
	array = new int [len];
    }
    int [] o;
    scatter (0, len, array, o, MPI_COMM_WORLD);
    
    foreach (ref it ; o)
	it = uniform (1, len);
    
    gather (0, len, o, array, MPI_COMM_WORLD);
    
    auto res = parallelReduce!((a, b) => (a > b) ? a : b) (total, array, len);
    syncWriteln (res);
    if (id == 0) {
	writeln ("SOMME : ", reduce!((a, b) => (a < b) ? a : b) (res), "\n");
    }
    syncWriteln (Clock.currTime - begin);
}

void main (string [] args) {
    auto adm = new Admin!foo (args);
    adm.finalize ();

}
