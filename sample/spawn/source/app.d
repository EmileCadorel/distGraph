import std.stdio;
import assign.fork;
import std.typecons, std.conv;

int foo (uint id, uint nb) {
    if (id % 2 == 0) {
	send ((id + 1) % nb, id, tuple(1, [1, 2, 4]));
    } else {
	int _id; Tuple!(int, int[]) a;
	receive (_id, a);
	writeln (a);
    }
    return 0;
}


void main(string [] args) {
    join (spawn!foo (args [1].to!uint));

}
