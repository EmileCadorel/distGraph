import std.stdio;
import mpiez.admin, mpiez.StateAdmin;
import std.conv, std.datetime;
import utils.Options;

class Proto : Protocol {

    this (int id, int total) {
	super (id, total);
	this.ping = new Message!(1, ulong);
    }

    Message!(1, ulong) ping;
}

void pong (int id, int total) {
    auto proto = new Proto (id, total);
    auto comm = proto.parent ();
    auto info = proto.commInfo (comm);
    receive ( 
	(int id, ulong msg) {
	    writeln (id, " => ", msg);
	    proto.ping (id, 1, comm);
	},
	comm
    );
}

void ping (int id, int total) {
    auto proto = new Proto (id, total);
    auto nb = to!int (Options ["-n"]);
    auto slaveComm = proto.spawn!"slave" (nb, []);
    foreach (it ; 0 .. nb) {
	proto.ping (it, 1, slaveComm);
	receive (
	    (int id, ulong msg) {
		writeln (id, " => ", msg);
	    },
	    slaveComm
	);
    }
}

void main (string [] args) {
    auto adm = new StateAdmin!(ping, "master", pong, "slave") (args);
    adm.finalize ();
}
