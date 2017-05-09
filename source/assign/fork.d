module assign.fork;
import std.stdio, std.array;
import utils.Singleton;

private {
    extern (C) int fork ();
    extern (C) int getpid ();
    extern (C) void pipe (int *);
    extern (C) void close (int);
    extern (C) void exit (int);
    extern (C) void write (int, void*, int);
    extern (C) void read (int, void*, int);
    extern (C) void wait (int, int*, int);
    extern (C) void flock (int, int);

    enum Locks {
	LOCK_SH = 1,
	LOCK_EX = 2,
	LOCK_UN = 8
    }
    
    class PipeContainer {
	import std.container;
    
	private int[2][uint]  _pipes;

	private Array!(int [2]) _p2c;

	private Array!(int[2]) _c2p;
    
	private uint _thisId;
    
	/++
	 Ajoute un nouveau set de pipes au conteneur
	 +/
	void insertPipes (int [2] p2c, int [2] c2p) {
	    this._p2c.insertBack (p2c);
	    this._c2p.insertBack (c2p);
	}
    
	/++
	 Params:
	 id = un identifiant de processus
	 Returns: le pipe coté lecture du process id
	 +/
	int read (uint id) {	
	    return this._pipes [id][1];
	}

	/++
	 Params:
	 id = un identifiant de processus
	 Returns: le pipe coté écriture du process id
	 +/
	int write (uint id) {
	    return this._pipes [id][0];
	}

	void thisId (uint id) {	
	    this._thisId = id;
	    foreach (it ; 0 .. _p2c.length) {
		if (it == id) {
		    close (this._p2c [id][0]);
		    close (this._c2p [id][1]);
		    this._pipes [id] = [this._p2c [id][1], this._c2p [id][0]];
		} else {
		    close (this._c2p [it][0]);
		    close (this._p2c [it][1]);
		    this._pipes [cast(uint)it] = [this._c2p [it][1], this._p2c [it][0]];
		}
	    }
	    this._c2p.clear ();
	    this._p2c.clear ();
	}
    
	/++
	 Returns: l'id du process
	 +/
	uint thisId () {
	    return this._thisId;
	}

	ulong nbPipes () {
	    return this._pipes.length;
	}    
    
	mixin Singleton;
    }
}
uint thisId () {
    return PipeContainer.instance.thisId;
}


uint[] spawn (alias fun) (uint nb) {
    auto ids = new uint [nb];    
    bool father = true;

    foreach (it ; 0 .. nb) {
	int [2] p2c, c2p;
	pipe (p2c.ptr);
	pipe (c2p.ptr);
	PipeContainer.instance.insertPipes (p2c, c2p);
    }
    
    foreach (it ; 0 .. nb) {
	if (father) {
	    auto id = fork ();	
	    if (id == 0) { // Le fils		
		PipeContainer.instance.thisId = it;
		father = false;
	    } else
		ids [it] = id;
	}
    }

    if (!father) {
	exit (fun (PipeContainer.instance.thisId, nb));
    }
    return ids;
}

void join (uint [] ids) {
    foreach (it ; ids) {
	auto stats = 0;
	wait (it, &stats, 0);
    }	
}

void send (T...) (uint id, T msgs) {
    if (thisId == id) assert (false, "Send message to itself");
    else {
	auto pipe = PipeContainer.instance.write (id);
	flock (pipe, Locks.LOCK_EX);
	sendWPipe (pipe, msgs);
	flock (pipe, Locks.LOCK_UN);
    }
}

private void sendWPipe (T, TNext ...)(int pipe, T msg, TNext next) {
    sendWPipe (pipe, msg);
    sendWPipe (pipe, next);
}

private void sendWPipe (T) (int pipe, T elem) if (!is (T a == struct) && !is (T a == class)) {
    write (pipe, &elem, elem.sizeof); 
}

private void sendWPipe (T) (int pipe, T elem) if (is (T a == struct)) {
    import std.typecons;
    sendWPipe (pipe, tuple(elem.tupleof).expand);
 }

private void sendWPipe (T : U[], U) (int pipe, T elem) {
    auto len = elem.length;
    write (pipe, &len, ulong.sizeof);
    write (pipe, elem.ptr, cast(int) (elem.length * U.sizeof));
}

void receive (T...) (ref T msg) {
    auto pipe = PipeContainer.instance.read (thisId);
    receiveWPipe (pipe, msg);    
}

private void receiveWPipe (T, TNext ...) (int pipe, ref T msg, ref TNext next) {
    receiveWPipe (pipe, msg);
    receiveWPipe (pipe, next);
}

private void receiveWPipe (T) (int pipe, ref T msg) if (!is (T a == struct) && !is (T a == class)) {
    read (pipe, &msg, msg.sizeof);
}

private void receiveWPipe (T : U [], U) (int pipe, ref T msg) {
    ulong len;
    read (pipe, &len, len.sizeof);
    msg = new U [len];
    read (pipe, msg.ptr, cast(int)(len * U.sizeof));
}

private void receiveWPipe (T) (int pipe, ref T msg) if (is (T a == struct)) {
    import std.typecons;
    auto a = tuple(msg.tupleof);
    receiveWPipe (pipe, a.expand);
    msg.tupleof = a;
 }










