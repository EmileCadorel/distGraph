import std.stdio;
import std.concurrency;
import std.typecons;

void testReceive (Tid ownerTid) {
    receive (
	(string value, Tid i) {
	    writeln ("Receive string : ", value);
	    send (i, "pong");
	}
    );
}

void testSend (Tid ownerTid) {

    receive(
        (Tid i) {
	    writeln("Received the Tid ", i);
	    send (i, "ping", thisTid);
	}
    );

    receive (
	(string value) {
	    writeln ("Received value : ", value);
	}
    );
    
    send (ownerTid, true);
}

void main() {
    // Start spawnedFunc in a new thread.
    auto childTid = spawn(&testSend, thisTid);
    auto childTid2 = spawn (&testReceive, thisTid);

    // Send the number 42 to this new thread.
    send(childTid, childTid2);

    // Receive the result code.
    auto wasSuccessful = receiveOnly!(bool);
    assert(wasSuccessful);
    writeln("Communication success.");
}
