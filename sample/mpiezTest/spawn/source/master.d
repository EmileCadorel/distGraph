import std.stdio;
import mpiez.admin;
import Proto;
import std.conv;

class Session : Process!Proto {

    private int _nbSlave;
    
    private MPI_Comm _slaveComm;

    this (string [] args, Proto p) {
	super (args, p);
	this._nbSlave = to!int (args [1]);
    }

    override void routine () {
	this._slaveComm = this.spawn ("./slave", this._nbSlave, ["salut"]);
	auto info = this.commInfo (this._slaveComm);
	writeln ("Master :", info [0], " ", info [1]);
	foreach (it; 0 .. this._nbSlave) {
	    this._proto.se (it, [it, it+ 2], this._slaveComm);
	    writefln ("Send to %d", it);
	}
    }

    override void onEnd () {
	this.freeComm (this._slaveComm);
    }        
}


void main (string [] args) {
    auto admin = new Admin!Session (args);
    admin.finalize ();
}
