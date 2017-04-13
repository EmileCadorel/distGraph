import std.stdio;
import mpiez.admin, mpiez.StateAdmin;
import std.conv;
import utils.Options;

class Proto : Protocol {

    this (int id, int total) {
	super (id, total);
	this.se = new Message!(2, ulong);
    }

    Message!(2, ulong) se;
}


class Slave : Process!Proto {
    
    this (Proto p) {
	super (p);
    }

    override void routine () {
	auto comm = this.parent ();
	auto info = this.commInfo (comm);
	ulong msg;
	this._proto.se.receive (0, msg, comm);
	writeln (thisId, " => ", msg);
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
	foreach (it; 0 .. this._nbSlave) {
	    this._proto.se (it, it, this._slaveComm);
	    writefln ("Send to %d", it);
	}
    }

    ~ this () {
	this.freeComm (this._slaveComm);	
    }
}

void main (string [] args) {
    auto adm = new StateAdmin!(Master, "master", Slave, "slave") (args);   
    adm.finalize ();
}
