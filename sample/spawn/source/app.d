import std.stdio;
import assign.admin;
import assign.socket.Protocol;
import assign.socket.Message;
import std.typecons, std.conv;
import std.string, core.time, core.thread;
import std.datetime, std.algorithm;
import assign.fork;
import std.container;

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
    writeln (addr, " => ", msg.length);
}

void pong (uint addr, int[] msg) {
    auto end = Clock.currTime - begins [addr - 1];
    writeln (addr, " <= ", msg.length, " took : ", end);    
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
    foreach (it ; Server.connected) {
	begins [it - 1] = Clock.currTime ();
	auto a = new int [100000];
	a.fill (1);
	writeln (it);
	Server.to!(Proto) (it).ping (a);
    }
}

void testAlloc () {
    import assign.data.Array;
    import assign.skeleton.Init;
    import assign.skeleton.Reduce;
    
    auto a = new DistArray!double (10_000_000);
    a.Init!(
	(ulong i) {
	    immutable n = 10_000_000;    
	    return (4.0) / (1.0 + (( i - 0.5 ) * (1.0 / n)) * (( i - 0.5 ) * (1.0 / n)));
	}
    );
    
    auto res = a.Reduce!((double a, double b) => a + b);
    writeln (res);
    delete a;
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
    while (true) {
	write ("? > ");
	auto line = readln ();
	if (line.strip == "stop") break;
	else if (line.strip == "ping") testPing ();
	else if (line.strip == "alloc") testAlloc ();
	else if (line.strip == "add") addMachine ();
    }	
    Server.toAll!(Proto, "end") (true);
    Server.kill ();    
}


int spawned (uint id, uint total) {
    int [] res;
    scatter (id, total, res);
    writeln ("Final res : ", id, ' ', res);
    return 0;
}


void main(string [] args) {
    auto adm = new AssignAdmin!(Proto, foo) (args);
    foo ();
    adm.join ();
    writeln ("End");
}
