import std.stdio;
import assign.admin;
import assign.socket.Protocol;
import assign.socket.Message;
import std.typecons, std.conv;
import std.string, core.time, core.thread;
import std.datetime, std.algorithm;

class Proto : Protocol {

    this () {
	this.ping = new Message!(1, int[]) (this);
	this.pong = new Message!(2, int[]) (this);
	this.end = new Message!(3, bool) (this);
	this.ready = new Message!(4, bool) (this);
    }

    Message!(1, int[]) ping;
    Message!(2, int[]) pong;
    Message!(3, bool) end;
    Message!(4, bool) ready;
}

__gshared SysTime [3] begins;



void ping (uint addr, int[] msg) {
    Server.to!(Proto) (addr).pong (msg);	    
    writeln (addr, " => ");
}

void pong (uint addr, int[] msg) {
    auto end = Clock.currTime - begins [addr - 1];
    writeln (addr, " <= ", " took : ", end);    
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

void testPing () {
    foreach (it ; 1 .. Server.lastMachine + 1) {
	begins [it - 1] = Clock.currTime ();
	auto a = new int [100000];
	a.fill (1);
	Server.to!(Proto) (it).ping (a);
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
	    else if (line.strip == "ping") testPing ();
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
