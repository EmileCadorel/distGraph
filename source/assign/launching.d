module assign.launching;
import std.stdio;
import libssh.session;
import libssh.channel;
import libssh.scp;
import libssh.errors;
import libssh.key;
import libssh.utils;
import std.string, std.conv;
import std.process, std.file;
import libssh.c_bindings.libssh;
import std.concurrency, std.datetime;

import assign.socket.Socket, assign.socket.Protocol;
import assign.ssh.connect_ssh;
import utils.Singleton;
import core.thread;
import sock = std.socket;
import std.container, core.exception;

immutable script_sh = 
    q{read LOWERPORT UPPERPORT < /proc/sys/net/ipv4/ip_local_port_range
      while :
      do
	      PORT="`shuf -i $LOWERPORT-$UPPERPORT -n 1`"
              ss -lpn | grep -q ":$PORT " || break
      done
      echo -e $PORT};

alias Server = ServerS.instance;

T Server (T : Protocol) () {
    return cast(T) (ServerS.instance.proto);
}

class ServerS {

    private Socket _socket;

    private bool _end = false;
       
    private Tid _compose;

    private SList!Thread _clients;
    
    private ushort _port;

    private Protocol _proto;    
    
    /++ Les sockets qui serve à la connexion des clients +/
    private Socket [uint] _clientOuts;

    /++ Les sockets qui servent à recevoir des informations des clients +/
    private Socket [uint] _clientIns;        
    
    private string _ownIp;

    private bool ownerIsWaiting = false;

    private uint _machineId = 0UL;

    private uint _lastMachine = 0UL;
   
    
    this () {	
	script_sh.toFile ("distGraph.findPort.sh");
	this._port = executeShell ("bash distGraph.findPort.sh").output.strip.to!ushort;
	executeShell ("rm distGraph.findPort.sh");
	this._proto = new Protocol ();
    }

    /++
     Lance le serveur qui ve servir à communiquer avec l'exterieur
     Params:
     port = le port du serveur
     +/
    void start () {		
	this._socket = new Socket (this._port);
	this._socket.bind ();
	this._socket.listen ();
	this._compose = spawn (&run, thisTid);
    }    

    private static void run (Tid ownerTid) {
	writeln ("Server launched on port : ", Server._port);
	try {
	    while (!Server._end) {
		auto client = Server._socket.accept ();
		auto pck = client.recv!(ushort, uint);
		Server._clientIns [pck [1]] = client;
		writeln ("Nouveau client ", client.remoteAddress.address, ' ', pck [0], ' ', pck [1]);
		Server._lastMachine = pck [1];
		auto addr = client.remoteAddress.address;
		Server._clients.insertFront (new clientRoutine(pck [1]).start);
		
		if (pck [0] != 0 && !(pck [1] in Server._clientOuts)) {
		    auto sock = new Socket (addr, pck [0]);
		    sock.connect ();
		    Server._clientOuts [pck[1]] = sock;
		    sock.sendDatas (cast(ushort)0, Server._machineId);
		} else {
		    writeln ("ACK ", addr);
		}
		
		if (Server.ownerIsWaiting) {
		    send (ownerTid, addr);
		    Server.ownerIsWaiting = false;
		}
		writeln ("Fin nouveau client");
	    }
	} catch (sock.SocketAcceptException exp) {
	    // Lorsqu'on kill le serveur accept jete une exception
	}

	send (ownerTid, true);
    }

    static class  clientRoutine : Thread {

	private uint machine;
	
	this (uint machine) {
	    super (&this.run);
	    this.machine = machine;
	}
	
	void run () {
	    writeln ("Debut routine client ", this.machine);
	    auto sock = Server._clientIns [this.machine];
	    while (!Server._end) {
		auto id = sock.recvId ();
		if (id == -1) break;
		else {
		    if (auto elem = (id in Server.proto.regMsg)) {
			elem.recv (sock, machine);
		    } else {
			auto msg = format("%d, %s", id, sock.recv_all ().to!string);
			assert (false, msg); 
		    }
		}
	    }
	
	    Server._clientIns.remove (machine);

	    if (machine in Server._clientOuts) {
		Server._clientOuts[machine].shutdown;	
		Server._clientOuts.remove (machine);
	    }
	
	    writeln ("Fin routine client ", machine);

	    if (Server._clientIns.length == 0 && Server.machineId != 0)
		Server.kill ();
	    
	    sock.shutdown ();
	}
    }

    public void setProtocol (T : Protocol) (T proto) {
	this._proto = proto;
    }

    Protocol proto () {
	return this._proto;
    }

    T to (T : Protocol) (uint machine) {
	writefln ("Message vers Machine %d", machine);
	auto sock = this._clientOuts [machine];
	this._proto.socket = sock;
	return cast (T) (this._proto);
    }

    void toAll (T : Protocol, string elem, TArgs ...) (TArgs params) {
	auto proto = cast (T) this._proto;
	foreach (value ; this._clientOuts) {
	    writeln ("Send to ", value.remoteAddress);
	    proto.socket = value;
	    mixin ("proto." ~ elem) (params);
	}
    }
    
    public auto receiveFrom (T ... ) (uint machine) {
	return this._clientIns [machine].recv!(T);
    }
    
    public void sendTo (T ...) (uint machine, T values) {
	return this._clientOuts [machine].send (values);
    }

    /++
     Etablis une connexion peer-to-peer avec un autre serveur
     Params:
     
     +/
    void handShake (string addr, ushort port, uint id) {
	auto sock = new Socket (addr, port);
	sock.connect ();
	this._clientOuts [id] = sock;
	sock.send (new Package (this._port, this._machineId));
	Server.ownerIsWaiting = true;
	receiveTimeout (
	    dur!"seconds"(5),
	    (string a) {
		if (addr != a)
		    assert (false, "J'ai échoué");
	    }
	);
	stdout.flush ();
    }

    ref string ownIp () {
	return this._ownIp;
    }
    
    /++
     Returns: le port du serveur
     +/
    ushort port () {
	return this._port;
    }

    void machineId (uint id) {
	this._machineId = id;
	writefln ("Machine identifié par %d", id);
    }
    
    uint machineId () {	
	return this._machineId;
    }

    ref uint lastMachine () {
	return this._lastMachine;
    }

    
    /++
     Arrête l'instance du serveur
     +/
    void kill () {
	import core.thread;
	if (!this._end) {
	    writeln ("Server killed on port : ", this._port);
	    foreach (key, value; this._clientIns) {
		writeln ("Stop connexion entrante ", key);
		value.shutdown ();
	    }
	    foreach (key, value; this._clientOuts) {
		writeln ("Stop connexion sortante ", key);
		value.shutdown ();
	    }

	    this._clientIns.clear ();
	    this._clientOuts.clear ();

	    // On coupe la boucle principale
	    this._socket.shutdown ();
	    this._socket = null;
	    this._end = true;
	}
    }

    void join () {
	import core.thread;
	if (!this._end) {
	    auto end = receiveOnly !bool;
	    writeln ("end");
	    assert (end);
	}
    }
    
    mixin ThreadSafeSingleton;
    
}
/++
 Lance une instance du programme sur une machine distante 
 Params:
 username = le compte présent sur la machine distante
 ip = l'ip de la machine
 pass = le mot de passe du compte
+/
void launchInstance (string username, string ip, string pass, string path) {
    import std.path;
    scope (exit) sshFinalize ();
    
    auto session = sessionConnect (ip, username, pass, LogVerbosity.NoLog);
    if (session is null) {
	assert (false, "Connexion failed");
    }

    try {
	auto channel = session.newChannel();
        scope(exit) channel.dispose();

        channel.openSession();
        scope(exit) channel.close();
	
	if (path == "" || path is null) {
	    writeln ("Scp de l'executable ");
	    path = format("/tmp/distGraph.exec%d.exe", Server.lastMachine + 1UL);
	    import fl = std.file;
	    auto scp = session.newScp (SCPMode.Write | SCPMode.Recursive, path);
	    scp.init ();
	    scp.pushFile (path, fl.getSize (thisExePath), octal!744);
	    scp.write (fl.read (thisExePath));
	}

	
	auto socket = new sock.Socket (cast (sock.socket_t)session.fd, sock.AddressFamily.INET);
	auto addr = socket.localAddress.name;
	auto sock_in = new sock.InternetAddress (*(cast (sock.sockaddr_in*) addr));

	Server.ownIp = sock_in.toAddrString ~ ":" ~ Server.port.to!string;
	
	auto msg = format ("%s --ip %s --port %d --id %d --tid %d > %s.%d.txt", path, sock_in.toAddrString,
			   Server.port, Server.machineId, Server.lastMachine + 1UL, ip, Server.lastMachine + 1UL);
	
	Server.lastMachine += 1;
	writeln (msg);
	
        channel.requestExec(msg);
	      	
	channel.sendEof ();
	string servAddr;
	Server.ownerIsWaiting = true;
	auto rec = receiveTimeout (
	    dur!"seconds" (5),
	    (string addr) {
		if (addr != ip) 
		    assert (false, ip ~ "ne fonctionne pas " ~ addr);
	    }
	);
	if (!rec) 
	    assert (false, ip ~ "ne fonctionne pas " ~ servAddr);
	    
    } catch (SSHException ssh) {
	import core.stdc.string : strlen;

	auto code = ssh_get_error_code (cast(void*)session);
	auto str = ssh_get_error (cast(void*)session);
	auto msg = cast(string) (str [0 .. strlen (str)]);
	stderr.writefln("SSH exception. Code = %d/%d, Message: %s\n%s\n",
			ssh.errorCode, code, msg, ssh.msg);
	throw ssh;
    } catch (AssertError err) {
	writeln ("La tentative de connexion a échoué");
    }
}



