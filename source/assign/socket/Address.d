module assign.socket.Address;
import sock = std.socket;
import std.format;

/***
 Classe qui definie une adresse, tcp-ip
*/
class Address {

    this (sock.Address addr) {
	this.addr = addr;
    }

    string address () {
	return this.addr.toAddrString ();
    }

    string port () {
	return this.addr.toPortString ();
    }

    override string toString () {
	return format ("%s:%s", this.address, this.port);
    }
    
    
private:

    sock.Address addr;

}
