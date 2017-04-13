import std.stdio;
import mpiez.admin, mpiez.StateAdmin;
import Proto;
import std.conv;
import utils.Options;

class Slave : Process!Proto {
    
    this (Proto p) {
	super (p);
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

}

class Master : Process!Proto {

    private int _nbSlave;
    
    private MPI_Comm _slaveComm;

    this (Proto p) {
	super (p);
	this._nbSlave = to!int (Options ["-n"]);
    }

    override void routine () {
	this._slaveComm = this.spawn!"slave" (this._nbSlave, []);
	auto info = this.commInfo (this._slaveComm);
	writeln ("Master :", info [0], " ", info [1]);
	foreach (it; 0 .. this._nbSlave) {
	    this._proto.se (it, [it, it+ 2], this._slaveComm);
	    writefln ("Send to %d", it);
	}
    }

    ~ this () {
	this.freeComm (this._slaveComm);	
    }
}

class Test {}

void main (string [] args) {
    auto adm = new StateAdmin!(Master, "master", Slave, "slave") (args);   
    adm.finalize ();
}
