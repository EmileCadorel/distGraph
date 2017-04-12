import std.stdio;
import mpiez.admin;
import Proto;
import std.conv;

class Session : Process!Proto {
    
    this (string [] args, Proto p) {
	super (args, p);
    }

    override void routine () {
	auto comm = this.parent ();
	auto info = this.commInfo (comm);
	receive (
	    (int id, string msg) {
		writeln (id, " => ", msg);
	    },
	    (int id, ulong [] elems) {
		writeln (id, " => ", elems);
	    },
	    comm
	);
    }

    override void onEnd () {
    }
}


void main (string [] args) {
    auto admin = new Admin!Session (args);
    admin.finalize ();
}
