import std.stdio;
import mpiez.admin;
import Proto;
import std.conv;
import utils.Options;

class Session : Process!Proto {

    private int _nbSlave;
    
    private MPI_Comm _slaveComm;

    this (Proto p) {
	super (p);
	this._nbSlave = to!int (Options ["-n"]);
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
