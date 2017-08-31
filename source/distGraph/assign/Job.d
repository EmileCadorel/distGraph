module distGraph.assign.Job;
public import distGraph.utils.Allocation;
import pack = distGraph.assign.socket.Package;
import sock = distGraph.assign.socket.Socket;
import proto = distGraph.assign.socket.Protocol;
import distGraph.assign.launching;
import std.traits;
import core.thread;

import std.stdio, std.container, std.typecons;

/++
 La classe job est une classe très proche de la classe message, à ceci près qu'elle enregistre des tâches qui peuvent être éffectuer par un processus lorsqu'on le leurs demande.
 Example:
 ------- 
 let job = new Job!(1) (Reduce!((a : int, b : int) => a + b).job); 
 -------

+/
class JobS {        
    abstract void recv (sock.Socket sock, uint addr);        
}

enum JobType {
    START = 0,
    END = 1,
    STOP = 2
}


template New(T) if (is(T == class)) {
	static T New(Args...)(Args args) {
     	    return new T(args);
	}
}

class Job (FUN ...) : JobS {

    static assert (FUN.length == 2 || FUN.length == 3);
    static if (FUN.length == 3) {
	alias Stop = FUN [2];
    }
    
    alias Req = FUN [0];
    alias Resp = FUN [1];
    
    shared static ulong __tag__;
    
    static this () {
	__tag__ = Server.addJob (New!(Job!(Req, Resp)));
    }

    alias TArgsIn = ParameterTypeTuple!(Req) [1 .. $];
    alias TArgsOut = ParameterTypeTuple!(Resp) [1 .. $];
    
    override void recv (sock.Socket sock, uint addr) {
	import std.traits;
	pack.Package pck = new pack.Package ();
	auto ret = sock.recvOnly!JobType ();
	
	if (ret == JobType.START) {
	    auto data = sock.recv ();
	    auto ret_ = pck.unpack!(TArgsIn) (data);
	    Req (addr, ret_.expand);	
	} else if (ret == JobType.END) {
	    auto data = sock.recv ();
	    auto ret_ = pck.unpack!(TArgsOut) (data);
	    Resp (addr, ret_.expand);
	} else {	
	    auto id = sock.recvOnly!uint();
	    static if (FUN.length == 3)
		Stop (addr, id);
	}
    }

    static void response (sock.Socket sock, TArgsOut params) {
	sock.sendId (-1);
	pack.Package pck = new pack.Package ();
	auto name = pck.enpack (__tag__);
	auto to_send = pck.enpack (params);
	sock.send (name);
	sock.sendOnly (JobType.END);
	sock.send (to_send);
    }
    
    static void send (sock.Socket sock, TArgsIn params) {
	sock.sendId (-1);
	pack.Package pck = new pack.Package ();
	auto name = pck.enpack (__tag__);
	auto to_send = pck.enpack (params);
	sock.send (name);
	sock.sendOnly (JobType.START);
	sock.send (to_send);
    }    

    static void stop (sock.Socket sock, uint id) {
	sock.sendId (-1);
	sock.send (pack.Package.enpack (__tag__));
	sock.sendOnly (JobType.STOP);
	sock.sendOnly (id);
    }
   
}




