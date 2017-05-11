module assign.socket.Socket;
public import assign.socket.Package;
import sock = std.socket;
import std.stdio;
import std.exception;
import assign.socket.Address;
import assign.socket.Error;

class Socket {   

    class UnknownHost : Exception {
	this(string addr) {
	    super ("Adresse inconnu : " ~ addr);
	}
    }

    /++
     Lancement d'une socket tcp coté client
     Params:
     addr = l'addresse du serveur
     port = le port du serveur     
     +/
    this (string addr, ushort port) {
	try {
	    auto addresses = sock.getAddress (addr, port);
	    if (addresses.length == 0) {
		throw new UnknownHost (addr);
	    }
	    this._addrstr = addr;
	    this._addr = addresses[0];
	    this._port = port;
	    this._socket = new sock.TcpSocket ();
	    this._socket.setOption (sock.SocketOptionLevel.SOCKET, sock.SocketOption.REUSEADDR, true);
	} catch (Exception exp) {
	    throw new ConnectionRefused (addr, port);
	}	
    }

    /++
     Lance un serveur sur le port
     Params:
     port = le port du serveur
     +/
    this (ushort port) {
	try {
	    this._port = port;
	    this._socket = new sock.TcpSocket ();
	    this._socket.setOption (sock.SocketOptionLevel.SOCKET, sock.SocketOption.REUSEADDR, true);
	} catch (Exception exp) {
	    throw new BindRefused (port);
	}
    }
        
    void connect () {
	try {
	    this._socket.connect (this._addr);
	} catch (Exception exp) {
	    throw new ConnectionRefused (this._addrstr, this._port);
	}
    }

    void bind () {
	try {
	    this._socket.bind (new sock.InternetAddress(this._port));
	} catch (Exception exp) {
	    throw new BindRefused (this._port);
	}
    }

    void listen () {
	this._socket.listen (1);
    }	  
	    
    void sendId (ulong id) {
	this._socket.send ([id]);
    }

    void send (void [] data) {
	this._socket.send ([data.length]);
	this._socket.send (data);
    }
    
    void send (Package pack) {
	this._socket.send ([pack.data.length]);
	this._socket.send (pack.data);
    }

    void sendDatas (T ...) (T elems) {
	auto pack = new Package (elems);
	this._socket.send ([pack.data.length]);
	this._socket.send (pack.data);
    }
    
    auto recv (T...) () if (T.length > 1) {
	import std.typecons;
	auto data = this.recv ();
	writeln (data.length, ' ', data);
	Tuple!(T) tu;
	return Package.unpack!(T) (data);
    }

    auto recv (T...) () if (T.length == 1) {
	import std.typecons;
	ulong [1] size;
	this._socket.receive (size);
	void [] data = new void [size [0]];
	this._socket.receive (data);
	return Package.unpack!(T) (data) [0];
    }

    
    /++
     Récupère toutes les données qui arrive sur la socket
     +/
    void [] recv_all () {
	byte [] total;
	while (true) {
	    byte [] data;
	    data.length = 256;
	    auto length = this._socket.receive(data);
	    total ~= data;
	    if (length < 256) return total;
	}
    }

    /++
     Récupère des données qui arrive sur la socket (identifié par un ulong qui arrive en premier)
     +/
    void [] recv () {
	ulong [1] size;
	this._socket.receive(size);
	void[] data;
	data.length = size[0];
	this._socket.receive (data);
	return data;
    }

    /++
     Récupère un long sur la socket
     +/
    long recvId () {
	long [1] id;
	auto length = this._socket.receive(id);
	if (length == 0) return -1;
	return id[0];
    }
    
    Socket accept () {
	auto sock = this._socket.accept ();
	return new Socket (sock);
    }

    Address localAddress () {
	return new Address (this._socket.localAddress ());
    }
    
    string hostName () {
	return this._socket.hostName ();
    }
    
    Address remoteAddress () {
	return new Address (this._socket.remoteAddress ());
    }

    /++
     Eteins la socket, des deux coté, client comme serveur
     +/
    void shutdown () {       
	this._socket.shutdown (sock.SocketShutdown.BOTH);
	this._socket.close ();
    }    
    
    ~this () {
    }
    
private:

    this (sock.Socket ot) {
	this._socket = ot;
    }
    
    sock.Socket _socket;
    string _addrstr;
    sock.Address _addr;
    ushort _port;
}
