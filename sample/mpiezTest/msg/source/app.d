import std.stdio;
import mpiez.admin;
import Master, Slave, Proto;
import std.datetime, std.conv;


class Session : Process!Proto {

    private string _filename;

    SysTime _begin;

    private ulong _nbPart;
    
    private float _lambda;
    
    private ulong _nbEdge;
    
    this (string [] args, Proto p) {
	super (args, p);
	this._filename = args [1];
	this._nbPart = to!ulong (args [2]);
	this._lambda = to!float (args [3]);
	this._begin = Clock.currTime ();	    
    }    

    override void routine () {
	if (thisId == 0) {
	    master ();
	} else {
	    slave ();
	}
    }      

    void master () {
	auto master = new Master (this._proto, this._filename, this._nbPart);
	master.run ();
    }

    void slave () {
	auto slave = new Slave (this._proto, this._lambda);
	slave.run ();
	this._nbEdge = slave.nbEdges;
    }
    
    override void onEnd () {
	syncFunc ((int id, ulong nbEdge, SysTime begin) {
		auto end = Clock.currTime;
		writef ("Fin du Process %d qui a traité %d arete(s) en  ", id, nbEdge);
		writeln (to!Duration (end - begin));
	    },
	    this._proto.id,
	    this._nbEdge,
	    this._begin
	);
    }
    
}


void main (string [] args) {
    auto admin = new Admin!Session (args);
    admin.finalize ();
}
