module distGraph.assign.socket.Protocol;
public import msg = distGraph.assign.socket.Message;
import sock = distGraph.assign.socket.Socket;

class Protocol {

    void register (msg.MessageBase msg) {
	this.regMsg [msg.id] = msg;
    }

    sock.Socket socket;
    msg.MessageBase [ulong] regMsg;
    
}

