import std.stdio;
import assign.admin;
import assign.socket.Protocol;
import assign.socket.Message;
import std.typecons, std.conv;
import std.string, core.time, core.thread;

class Proto : Protocol {

    this () {
	this.ping = new Message!(1, string) (this);
	this.pong = new Message!(2, string) (this);
	this.end = new Message!(3, bool) (this);
	this.ready = new Message!(4, bool) (this);
    }

    Message!(1, string) ping;
    Message!(2, string) pong;
    Message!(3, bool) end;
    Message!(4, bool) ready;
}

void ping (uint addr, string msg) {
    writeln (addr, " => ", msg);
    Server.to!(Proto) (addr).pong ("Hi !!");	    
}

void pong (uint addr, string msg) {
    writeln (addr, " <= ", msg);    
}

void end (uint addr, bool val) {
    writeln ("Kill recv");
    Server.kill ();
}

void ready (uint addr, bool val) {
    if (val) {
	writeln ("Machine prête");
    }
}

void addMachine () {
    import std.algorithm : any;
    write ("user@ip:path[pass] ?> ");
    auto line = readln ();
    auto atIndex = line.indexOf ("@");
    auto colonIndex = line.indexOf(":");
    auto croIndex = line.indexOf ("[");
    auto rcroIndex = line.indexOf ("]");
    if (any!"a == -1" ([atIndex, colonIndex, croIndex, rcroIndex])) {
	writeln ("Malformed");
    } else {
	auto user = line [0 .. atIndex].strip;
	auto ip = line [atIndex + 1 .. colonIndex].strip;
	auto path = line [colonIndex + 1 .. croIndex].strip;
	auto pass = line  [croIndex + 1 .. rcroIndex].strip;
	launchInstance (user, ip, pass, path);

	foreach (it ; 1 .. Server.lastMachine + 1) {
	    Server.to!(Proto) (it).ping ("Hello");
	}
	
    }
}


void foo () {
    Server!(Proto).end.connect (&end);
    Server!(Proto).ping.connect (&ping);
    Server!(Proto).pong.connect (&pong);
    Server!(Proto).ready.connect (&ready);
    
    writefln ("Machine %d correctement lancé", Server.machineId);    
    if (Server.machineId == 0) {	
	while (true) {
	    write ("? > ");
	    auto line = readln ();
	    if (line.strip == "stop") break;
	    else if (line.strip == "add") addMachine ();
	}	
	Server.toAll!(Proto, "end") (true);
	Server.kill ();
    }
}

void main(string [] args) {    
    auto adm = new AssignAdmin!(Proto, foo) (args);
    adm.join ();       
    writeln ("End");
}
