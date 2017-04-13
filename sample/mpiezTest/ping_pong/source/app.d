import std.stdio;
import mpiez.admin;

class Proto : Protocol {

    this (int id, int total) {
	super (id, total);
	this.ping = new Message!(1, int);
	this.pong = new Message!(2, int);
    }

    Message!(1, int) ping;
    Message!(2, int) pong;
}

class Session : Process!Proto {

    this (Proto p) {
	super (p);
    }

    override void routine () {
	int value;
	if (thisId % 2 == 0) {
	    this._proto.ping (thisId + 1, 42);
	    this._proto.pong.receive (thisId + 1, value);
	    writeln (thisId, " <- ", value, " pong");
	} else {
	    this._proto.ping.receive (thisId - 1, value);
	    writeln (thisId, " <= ", value, " ping");
	    this._proto.pong (thisId - 1, 24);	   		
	}
    }
    
    override void onEnd () {
	syncFunc (
		  (int id) {
		      writeln ("Process ", id, " fin");
		  }, thisId
		  );
    }
    
}




void main (string [] args) {
    auto adm = new Admin!Session (args);
    adm.finalize ();
}
