module assign.socket.Error;
import std.exception;
import std.conv;

class SocketError : Exception {
    this (string msg) {
	super (msg);
    }
}

class UsageError : SocketError {
    this (string info) {
	super ("usage " ~ info);
    }        
}

class OptionError : SocketError {
    this (string option) {
	super ("Option inconnu " ~ option);	
    }    
}

class ConnectionRefused : SocketError {
    this (string addr, ushort port) {
	super ("connection refuse " ~ addr ~ ":" ~ to!string(port));
    }    
}

class BindRefused : SocketError {
    this (ushort port) {
	super ("bind: permission non-accorde port:" ~ to!string (port));
    }    
}




