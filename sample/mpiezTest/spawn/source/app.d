import std.stdio;
import mpiez.admin, mpiez.StateAdmin;
import std.conv, std.datetime;
import utils.Options;

class Proto : Protocol {

    this (int id, int total) {
	super (id, total);
	this.se = new Message!(2, ulong);
    }

    Message!(2, ulong) se;
}

void slave (int id, int total) {
    auto proto = new Proto (id, total);
    ulong msg;
    auto comm = proto.parent ();
    proto.se.receive (0, msg, comm);
    writeln (id, " => ", msg);
}

void master (int id, int total) {
    auto proto = new Proto (id, total);
    auto nb = to!int (Options ["-n"]);
    auto slaveComm = proto.spawn!"slave" (nb, []);
    foreach (it ; 0 .. nb)
	proto.se (it, it, slaveComm);
}

void main (string [] args) {
    auto adm = new StateAdmin!(master, "master", slave, "slave") (args);
    adm.finalize ();
}
