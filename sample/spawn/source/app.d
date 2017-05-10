import std.stdio;
import assign.launching;
import std.typecons, std.conv;
import std.string;

void main(string [] args) {
    if (args.length == 1) {	
	launchInstance ("emile", "192.168.80.63", "truc", "/home/emile/Documents/stage/repos/sample/spawn/spawn");	
	Server.sendTo ("192.168.80.63", "Hi !!");
    } else {
	writeln ("launched with port ", args [1], ":", args[2]);
	Server.handShake (args[1], args [2].to!ushort);
	auto msg = Server.receiveFrom !(string) (args[1]);
	writeln (msg);
    }
    
    Server.kill ();    
}
