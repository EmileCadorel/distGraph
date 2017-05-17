module assign.Job;
import pack = assign.socket.Package;
import sock = assign.socket.Socket;
import proto = assign.socket.Protocol;
import assign.launching;

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

class Job (alias Req, alias Resp) : JobS {
    
    static this () {
	Server.addJob (new Job!(Req, Resp), typeid (Job!(Req, Resp)).toString);
    }
    
    override void recv (sock.Socket sock, uint addr) {
	import std.traits;
	pack.Package pck = new pack.Package ();
	auto ret = sock.recvOnly!bool ();
	if (ret == true) {
	    auto data = sock.recv ();
	    auto ret_ = pck.unpack!(ParameterTypeTuple!(Req) [1 .. $]) (data);
	    Req (addr, ret_.expand);	
	} else {
	    auto data = sock.recv ();
	    auto ret_ = pck.unpack!(ParameterTypeTuple!(Resp) [1 .. $]) (data);
	    Resp (addr, ret_.expand);
	}
    }

    void response (TArgs...) (sock.Socket sock, uint jbId, TArgs params) {
	sock.sendId (-1);
	pack.Package pck = new pack.Package ();
	auto name = pck.enpack (typeid (this).toString);
	auto to_send = pck.enpack (jbId, params);
	sock.send (name);
	sock.sendOnly (false);
	sock.send (to_send);
    }
    
    void send (TArgs...) (sock.Socket sock, uint jbId, TArgs params) {
	sock.sendId (-1);
	pack.Package pck = new pack.Package ();
	auto name = pck.enpack (typeid (this).toString);
	auto to_send = pck.enpack (jbId, params);
	sock.send (name);
	sock.sendOnly (true);
	sock.send (to_send);
    }    
   
}




