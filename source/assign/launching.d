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
import sock = std.socket;
import std.container;

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
    
    private ushort _port;

    private Protocol _proto;    
    
    /++ Les sockets qui serve à la connexion des clients +/
    private Socket [string] _clientOuts;

    /++ Les sockets qui servent à recevoir des informations des clients +/
    private Socket [string] _clientIns;    
    
    /++ Les identifiant des machine +/
    private string [uint] _MachineIds;
    
    static this () {
	// On récupère l'instance avant que le main ne se lance
	auto inst = Server.instance;
    }
    
    this () {	
	script_sh.toFile ("distGraph.findPort.sh");
	this._port = executeShell ("bash distGraph.findPort.sh").output.strip.to!ushort;
	executeShell ("rm distGraph.findPort.sh");
	this._proto = new Protocol ();
	start ();
    }

    /++
     Lance le serveur qui ve servir à communiquer avec l'exterieur
     Params:
     port = le port du serveur
     +/
    private void start () {		
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
		writeln ("Nouveau client ", client.remoteAddress);		
		auto pck = client.recv!(ushort);
		auto addr = client.remoteAddress.address;
		Server._clientIns [addr] = client;
		spawn (&clientRoutine, addr);
		if (pck != 0) {
		    foreach (key, value; Server._clientOuts) {
			value.send (0UL, addr, pck);
		    }
		    
		    auto sock = new Socket (addr, pck);
		    sock.connect ();
		    Server._clientOuts [addr] = sock;
		    sock.send (0);
		} else {
		    writeln ("ACK ", addr);
		}
		send (ownerTid, addr);
	    }
	} catch (sock.SocketAcceptException exp) {
	    // Lorsqu'on kill le serveur accept jete une exception
	}

	send (ownerTid, true);
    }

    private static clientRoutine (string addr) {	
	auto sock = Server._clientIns [addr];
	while (!Server._end) {
	    auto id = sock.recvId();
	    if (id == -1) break;
	    else if (id == 0) {
		auto msg = sock.recv!(string, ushort);
		Server.handShake (msg.expand);
	    } else {
		if (auto elem = (id in Server.proto.regMsg)) {
		    elem.recv (sock, addr);
		}
	    }
	}
	sock.shutdown ();
    }

    public void setProtocol (T : Protocol) (T proto) {
	this._proto = proto;
    }

    Protocol proto () {
	return this._proto;
    }

    T to (T : Protocol) (string addr) {
	auto sock = this._clientOuts [addr];
	this._proto.socket = sock;
	return cast (T) (this._proto);
    }
    
    public auto receiveFrom (T ... ) (string machine) {
	return this._clientIns [machine].recv!(T);
    }
    
    public void sendTo (T ...) (string machine, T values) {
	return this._clientOuts [machine].send (values);
    }

    /++
     Etablis une connexion peer-to-peer avec un autre serveur
     Params:
     
     +/
    void handShake (string addr, ushort port) {
	auto sock = new Socket (addr, port);
	sock.connect ();
	this._clientOuts [addr] = sock;
	sock.send (new Package (this._port));
	receiveTimeout (
	    dur!"seconds"(5),
	    (string a) {
		if (addr != a)
		    assert (false, "J'ai échoué");
	    }
	);
    }
    
    /++
     Returns: le port du serveur
     +/
    ushort port () {
	return this._port;
    }

    /++
     Arrête l'instance du serveur
     +/
    void kill () {
	import core.thread;
	if (!this._end) {
	    writeln ("Server killed on port : ", this._port);
	    this._end = true;
	    this._socket.shutdown ();
	    this._socket = null;
	    auto recv = receiveOnly!(bool)();
	    if (!recv) assert (false, "Killing failed");
	    foreach (key, value; this._clientIns)
		value.shutdown ();
	    this._clientIns.clear ();
	    this._clientOuts.clear ();		
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
	
	auto scp = session.newScp (SCPMode.Write | SCPMode.Recursive, path);
	scp.init ();
	auto socket = new sock.Socket (cast (sock.socket_t)session.fd, sock.AddressFamily.INET);
	auto addr = socket.localAddress.name;
	auto sock_in = new sock.InternetAddress (*(cast (sock.sockaddr_in*) addr));
	
	writeln (path ~ " " ~ sock_in.toAddrString ~ " " ~ Server.port.to!string);
        channel.requestExec(path ~ " " ~ sock_in.toAddrString ~ " " ~ Server.port.to!string ~ " > " ~ ip ~ ".txt");

	      	
	channel.sendEof ();
	string servAddr;
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
    }    
}



