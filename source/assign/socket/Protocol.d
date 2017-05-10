module assign.socket.Protocol;
public import msg = assign.socket.Message;
import sock = assign.socket.Socket;

class Protocol {

    void register (msg.MessageBase msg) {
	this.regMsg [msg.id] = msg;
    }

    sock.Socket socket;
    msg.MessageBase [ulong] regMsg;
    
}

