module distGraph.assign.launching;
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

import distGraph.assign._;
import distGraph.utils.Singleton;
import core.thread;
import sock = std.socket;
import std.container, core.exception;
import std.algorithm : find;
import std.typecons, core.sync.mutex;


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

    /++ La socket interne du serveur +/
    private Socket _socket;

    /++ Le serveur doit il s'arreter +/
    private bool _end = true;

    /++ L'identifiant de la routine thread d'acceptation des clients +/
    private Tid _compose;

    /++ L'identifiant du main thread +/ 
    private Tid _global;
    
    /++ La liste des threads des clients connecté +/
    private SList!Thread _clients;

    /++ Le port du serveur +/
    private ushort _port;

    /++ Le protocol de message utilisé par le serveur +/
    private Protocol _proto;    
    
    /++ Les sockets qui serve à la connexion des clients +/
    private Socket [uint] _clientOuts;

    /++ Les sockets qui servent à recevoir des informations des clients +/
    private Socket [uint] _clientIns;        

    /++ L'ip de la machine qui possède le serveur +/
    private string _ownIp;

    /++ Vrai lors d'un handshake +/
    private bool ownerIsWaiting = false;

    /++ L'identifiant de la machine +/
    private uint _machineId = 0UL;

    /++ Le dernier identifiant de machine utilisé +/
    private uint _lastMachine = 0UL;

    /++ La liste des machines actuellement connecté +/
    private Array!uint _connected;

    /++ La liste des jobs +/
    private Array!JobS _jobs;

    /++ La liste des messages reçu par les communicateurs de threads +/     
    private Array!Variant _msgs;

    private Mutex _mutex;
    
    this () {
	this._mutex = new Mutex;
	this._global = thisTid;	
    }
    
    /++
     Lance le serveur qui ve servir à communiquer avec l'exterieur
     Params:
     port = le port du serveur
     +/
    void start () {
	auto file = File ("distGraph.findPort.sh", "w");
	file.write (script_sh);
	file.close ();
	auto res = executeShell ("bash distGraph.findPort.sh");
	if (res.status != 0) assert (false, res.status.to!string);
	this._port = res.output.strip.to!ushort;	
	executeShell ("rm distGraph.findPort.sh");
	this._end = false;
	
	this._socket = new Socket (this._port);
	this._socket.bind ();
	this._socket.listen ();
	this._compose = spawn (&run, thisTid);
    }    


    /++
     Routine principale du serveur. C'est ici qu'on accepte les clients.
     Params:
     ownerTid = le Tid du processus qui à lancé la routine     
     +/
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
		Server._connected.insertBack (pck [1]);
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

    /++ Classe interne threadé qui permet la communication avec les clients +/
    static class  clientRoutine : Thread {

	/++ L'identifiant de la machine qui est connecté +/
	private uint machine;
	
	this (uint machine) {
	    super (&this.run);
	    this.machine = machine;
	}

	/++ 
	 Routine principale du déroulement du client.
	 Envoi des signaux lorsqu'un message, ou un job est reçu.
	 Les jobs sont identifié en négatif. 
	 Le message 0 ferme le connexion.
	 +/
	void run () {	    
	    writeln ("Debut routine client ", this.machine);
	    auto sock = Server._clientIns [this.machine];
	    while (!Server._end) {
		long id;
		if (!sock.recvId (id)) {
		    writeln ("Socket fermé");
		    break;
		} else if (id > 0) {
		    if (auto elem = (id in Server.proto.regMsg)) {
			elem.recv (sock, machine);
		    } else {
			auto msg = format("Pas de message (%d)=> %s", id, sock.recv_all ().to!string);
			assert (false, msg); 
		    }
		} else if (id == -1) {
		    auto pack = new Package ();
		    auto name = pack.unpack! (ulong) (sock.recv ());
		    if (Server._jobs.length >= name [0]) {
			Server._jobs [name [0] - 1].recv (sock, machine);
		    } else {
			auto msg = format ("Pas de job (%s:%d)=> %s", name [0], sock.recv_all ().to!string);
			assert (false, msg);
		    }		    
		}
	    }

	    // On enleve la socket des sockets lisible en lecture.
	    Server._clientIns.remove (machine);

	    // Si on possède une socket en écriture on la supprime aussi.
	    if (machine in Server._clientOuts) {
		Server._clientOuts[machine].shutdown;	
		Server._clientOuts.remove (machine);
	    }
	
	    writeln ("Fin routine client ", machine);
	    
	    // On supprime l'identifiant de la machine dans la liste des machines connecté.
	    Server._connected.linearRemove (Server._connected [].find (this.machine));

	    // Si on ne possède plus aucune connexion et qu'on est pas le maître on ferme tout.
	    if (Server._clientIns.length == 0 && Server.machineId != 0)
		Server.kill ();
	    
	    sock.shutdown ();
	}
    }

    /++
     Returns: La liste des machines actuellement connecté au serveur.
     +/
    Array!uint connected () {
	return this._connected;
    }

    /++x
     La machine est elle connecté à une machine id
     Params:
     id = l'identifiant de la machine exterieur
     Retunrs: La connexion est présente ?
     +/
    bool isConnected (uint id) {
	import std.algorithm;
	return !(this._connected[].find (id).empty);
    }
    
    /++     
     Changement du protocol des messages.
     +/
    public void setProtocol (T : Protocol) (T proto) {
	this._proto = proto;
    }

    /++
     Returns: le protocol des messages.
     +/
    Protocol proto () {
	return this._proto;
    }

    /++
     Assigne le protocol à une machine pour préparer l'envoi.
     Params:
     machine = l'identifiant de la machine à qui ont veut envoyé (doit être dans connected);
     Returns: le protocol avec les bonnes sockets pour envoyer correctement.
     +/
    T to (T : Protocol) (uint machine) {
	writefln ("Message vers Machine %d", machine);
	auto sock = this._clientOuts [machine];
	this._proto.socket = sock;
	return cast (T) (this._proto);
    }

    /++
     Fais une demande de travail à une machine 
     Params:
     machine = l'identifiant de la machine
     job = le job a effectué
     params = les paramètres du travail
     +/
    void jobRequest (J : JobS, TArgs...) (uint machine, uint jbId, TArgs params) {
	auto sock = this._clientOuts [machine];
	J.send (sock, jbId, params);
    }

    /++
     Effectue un envoi de résultat de travail à une machine
     Params:
     machine = l'identifiant de la machine
     job = le job effectué
     params = les paramètres du job
     +/
    void jobResult (J : JobS, TArgs...) (uint machine, uint jbId, TArgs params) {
	auto sock = this._clientOuts [machine];
	J.response (sock, jbId, params);
    }       
    
    /++
     Effectue un requêtes au autres machines pour connaître leurs capacité mémoire
     Returns: un tableau assoc taille [id].
     +/
    ulong [uint] getMachinesFreeMemory () {
	import distGraph.assign.cpu, distGraph.assign.defaultJob;
	import CL = openclD._;
			
	ulong [uint] sizes;	
	sizes [this.machineId] = SystemInfo.memoryInfo.memAvailable;
	
	foreach (it ; this._connected) {
	    jobRequest!(MemoryJob) (it, 0U);
	    sizes [it] = this.waitMsg!(ulong) ();
	}
	return sizes;
    }    
    
    /++
     Envoi un message au main thread pour qu'il arrête d'attendre
     +/
    void sendMsg (T...) (T msg) {
	send (this._global, msg);
    }

    void sendMsgToTh (T ...) (Tid id, T msg) {
	send (id, msg);
    }
    
    /++
     Envoi un message au main thread pour qu'il arrête d'attendre
     +/
    void sendMsg (T) (shared T msg) {
	send (this._global, msg);
    }
    
    /++
     Le thread attend un message     
     +/
    T waitMsg (T) () {
	T to_ret; bool end = false;
	
	this._mutex.lock_nothrow ();
	foreach (it ; 0 .. this._msgs.length) {
	    if (this._msgs [it].type == typeid (T)) {
		to_ret = *(this._msgs [it].peek!T);
		end = true;
		this._msgs.linearRemove (this._msgs [it .. it + 1]);
		break;
	    }
	}	
	this._mutex.unlock_nothrow ();
	
	while (!end) {
	    receive (
		(T a) {
		    to_ret = a;
		    end = true;
		}, (Variant v) {
		    this._mutex.lock_nothrow ();
		    Server._msgs.insertBack (v);
		    this._mutex.unlock_nothrow ();
		}
	    );
	}
	
	return to_ret;
    }

    /++
     Le thread attend un message     
     +/
    void waitMsg (T...) (ref T res) {	
	res = waitMsg!(Tuple!(T)).expand;
    }

    
    /++
     Envoie un message du protocol à toutes les machines connecté au serveur.
     Params:
     T = le type de protocol utilisé
     elem = le nom du message (un attribut de T).
     params = les paramètres à passé au message.
     +/
    void toAll (T : Protocol, string elem, TArgs ...) (TArgs params) {
	auto proto = cast (T) this._proto;
	foreach (value ; this._clientOuts) {
	    writeln ("Send to ", value.remoteAddress);
	    proto.socket = value;
	    mixin ("proto." ~ elem) (params);
	}
    }
    
    /++
     Reçoi un message du client (machine), utilisez le système de message et de job plutot.
     Params:
     machine = la machine qui a envoyer le message 
     Returns: un tuple qui contient les valeurs reçu.
     +/
    deprecated public auto receiveFrom (T ... ) (uint machine) {
	return this._clientIns [machine].recv!(T);
    }

    /++
     Envoi un message à un client (machine), utilisez le système de message et de job plutot.
     Params:
     machin = la machine qui va recevoir le message
     values = les paramètres du messages qui vont être enpaqueté
     +/
    deprecated public void sendTo (T ...) (uint machine, T values) {
	return this._clientOuts [machine].send (values);
    }

    /++
     Envoi d'un message à tout les clients
     Params:
     id = l'identifiant du message
     except = l'identifiant de la machine à qui il ne faut pas envoyer le message.
     values = la liste des valeurs du message.
     +/
    deprecated public void sendToAll (T...) (ulong id, uint except, T values) {
	foreach (key, value ; this._clientOuts) {
	    if (key != except) {
		value.sendId (id);
		value.sendDatas (values);
	    }
	}
    }
    
    /++
     Etablis une connexion peer-to-peer avec un autre serveur
     Params:
     addr = l'adresse du deuxième serveur
     port = le port du deuxième serveur
     id = l'identifiant de la machine qui possède le serveur.
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

    /++
     Ajoute un job à la liste des jobs disponibles
     Params:
     job = le nouveau travail a enregistrer
     Returns: l'identifiant de ce travail
     +/
    ulong addJob (JobS job) {
	this._jobs.insertBack (job);
	return this._jobs.length;
    }
    
    /++
     Returns: l'ip de la machine qui possède le serveur.
     +/
    ref string ownIp () {
	return this._ownIp;
    }
    
    /++
     Returns: le port du serveur
     +/
    ushort port () {
	return this._port;
    }

    /++
     Params:
     id = le nouvelle identifiant de la machine.
     +/
    void machineId (uint id) {
	this._machineId = id;
	writefln ("Machine identifié par %d", id);
    }

    /++
     Returns: l'identifiant de la machine qui possède le serveur.
     +/
    uint machineId () {	
	return this._machineId;
    }

    /++
     Returns: l'identifiant de la dernière machine lancé (vrai que chez master).
     +/
    ref uint lastMachine () {
	return this._lastMachine;
    }

    /++
     Le serveur est lancé ?
     +/
    bool isStarted () {
	return !this._end;
    }
    
    /++
     Arrête l'instance du serveur, immédiatement.
     Ferme toutes les connexions.
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
	    
	    this._clientIns = null;
	    this._clientOuts = null;

	    // On coupe la boucle principale
	    this._socket.shutdown ();
	    this._socket = null;
	    this._end = true;
	}
    }

    /++
     Attends que le serveur ait términé son travail.
     Il ne termine uniquement quand on appelle la fonction kill.
     +/
    void join () {
	import core.thread;
	if (!this._end) {
	    auto end = receiveOnly !bool;
	    writeln ("end");
	    assert (end);
	}
    }

    /++ Le serveur est une instance de singleton (atomic, threadSafe) +/
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
    if (!Server.isStarted) {
	Server.start ();
    }
    
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

	/// L'executable n'est pas présent sur la nouvelle machine on le lui envoi.
	if (path == "" || path is null) {
	    writeln ("Scp de l'executable ");
	    path = format("/tmp/distGraph.exec%d.exe", Server.lastMachine + 1UL);
	    auto pathStr = "/tmp/cl_kernels/";
	    import fl = std.file;
	    auto scp = session.newScp (SCPMode.Write | SCPMode.Recursive, "/tmp");
	    scp.init ();
	    scp.pushFile (path, fl.getSize (thisExePath), octal!744);
	    scp.write (fl.read (thisExePath));

	    if (exists ("cl_kernels")) {
		scp.pushDirectory (pathStr, octal!744);
		foreach (string name; dirEntries ("cl_kernels", SpanMode.depth)) {
		    auto flName = name [name.lastIndexOf ("/") + 1 .. $];
		    scp.pushFile (flName, fl.getSize (name), octal!744);
		    scp.write (fl.read (name));
		}
	    }
	}

	/// On récupère l'addresse de la machine d'après la connexion ssh.
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
	auto rec = receiveTimeout ( // On attend que le handshake soit terminé (la machine à 5secondes pour répondre).
	    dur!"seconds" (5),
	    (string addr) {
		if (addr != ip) 
		    assert (false, ip ~ "ne fonctionne pas " ~ addr);
	    }
	);
	
	if (!rec) {
	    Server.lastMachine -= 1;
	    assert (false, ip ~ "ne fonctionne pas " ~ servAddr);
	}
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



