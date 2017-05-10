import std.stdio;
import assign.launching;
import assign.socket.Protocol;
import assign.socket.Message;
import std.typecons, std.conv;
import std.string, core.time, core.thread;

class Proto : Protocol {

    this () {
	this.ping = new Message!(1, string) (this);
    }

    Message!(1, string) ping;   
}

void foo (string addr, string msg) {
    writeln (addr, " => ", msg);
}

void main(string [] args) {
    Server.setProtocol (new Proto);
    Server!(Proto).ping.connect (&foo);

    
    if (args.length == 1) {	
	launchInstance ("emile", "192.168.80.63", "truc", "/home/emile/Documents/stage/repos/sample/spawn/spawn");	
	Server.to!(Proto) ("192.168.80.63").ping ("Hi !!");	
    } else {
	writeln ("launched with port ", args [1], ":", args[2]);
	Server.handShake (args[1], args [2].to!ushort);
	Server.to!(Proto) ("192.168.80.63").ping ("Hi !!");	
    }

    Thread.sleep (dur!"msecs" (100));
    Server.kill ();    
}
