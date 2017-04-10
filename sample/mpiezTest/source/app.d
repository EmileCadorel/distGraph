import std.stdio;
import mpiez.admin;

class Proto : Protocol {

    this (int id, int total) {
	super (id, total);
	this.first = new Message! (0, int);
	this.second = new Message!(1, string);
	this.third = new Message! (2, int []);
    }
    
    Message!(0, int) first;
    Message!(1, string) second;
    Message!(2, int[]) third;
}

class Session : Process!Proto {

    this (string [] args, Proto p) {
	super (args, p);
    }

    override void routine () {
	writefln ("Process %d started", this._proto.id);
	if (this._proto.id == 0) {
	    int value;
	    int [] value3;
	    string value2;
	    foreach (it ; 1 .. this._proto.total) {		
		this._proto.first.receive (it, value);
		this._proto.second.receive (it, value2);
		this._proto.third.receive (it, value3);
		writeln (value, " ", value2, " ", value3);
	    }
	} else {
	    writefln ("Proto %d, send message", this._proto.id);
	    this._proto.first (0, this._proto.id);
	    this._proto.second(0, "salut !!");
	    this._proto.third (0, [1, 2, 3]);
	}
    }

    override void onEnd () {
	syncFunc (function (int id) {
		writefln ("End of process %d", id);
	    }, this._proto.id);
    }

    ~this () {
	writeln ("Destruction");
    }
}

void main(string [] args) {    
    Admin!Session adm = new Admin!Session (args);
    adm.finalize ();
    writeln ("end?");
}
