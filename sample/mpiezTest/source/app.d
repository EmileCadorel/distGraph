import std.stdio;
import mpiez.admin;

class Proto : Protocol {

    this (int id, int total) {
	super (id, total);
	this.first = new Message! (0, int[]);
    }

    Message!(0, int[]) first;
    
}

class Session : Process!Proto {

    this (string [] args, Proto p) {
	super (args, p);
    }

    override void routine () {
	writefln ("Process %d started", this._proto.id);
    }

    override void onEnd () {
	syncFunc (function (int id) {
		writefln ("End of process %d", id);
	    }, this._proto.id);
    }
    
}



void main(string [] args) {    
    Admin!Session adm = new Admin!Session (args);
    adm.finalize ();
}
