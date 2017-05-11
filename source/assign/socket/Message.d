module assign.socket.Message;
import pack = assign.socket.Package;
import sock = assign.socket.Socket;
import proto = assign.socket.Protocol;

import std.stdio;
import std.container;
import std.typecons;

class MessageBase {
    ulong id ;
    abstract void recv (sock.Socket, uint);
}

/**
 Message permettant le communication entre une session client et une session serveur
 */
class Message (ulong ID, TArgs...) : MessageBase {

    static assert (ID > 0);
    
    this (proto.Protocol proto) {
	this.id = ID;
	proto.register (this);
	this._proto = proto;
    }
        
    void opCall (TArgs datas) {
	this._proto.socket.sendId (this.id);
	pack.Package pck = new pack.Package ();
	auto to_send = pck.enpack (datas);
	this._proto.socket.send (to_send);
    }

    void connect (void delegate(uint, TArgs) fun) {
	this.connections.insertFront (fun);
    }

    void connect (void function(uint, TArgs) fun) {
	this.foos.insertFront (fun);
    }
    
    override void recv (sock.Socket socket, uint addr) {
	auto data = socket.recv ();
	pack.Package pck = new pack.Package ();
	auto ret = pck.unpack!(TArgs) (data);
	foreach (it ; connections)
	    it (addr, ret.expand);
	foreach (it ; foos) 
	    it (addr, ret.expand);
    }
    
private:
       
    SList!(void delegate(uint, TArgs)) connections;
    SList!(void function(uint, TArgs)) foos;
    proto.Protocol _proto;
}
