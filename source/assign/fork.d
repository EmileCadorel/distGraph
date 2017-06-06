module assign.fork;
import std.stdio, std.array;
import utils.Singleton;
import std.traits;
import core.stdc.stdlib;

private {
    extern (C) int fork ();
    extern (C) int getpid ();
    extern (C) void pipe2 (int *, int);
    extern (C) void close (int);
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
    
	private uint _thisId = uint.max;
    
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
    if (nb > 0) {
	auto ids = new uint [nb];    
	bool father = true;
	
	foreach (it ; 0 .. nb + 1) {
	    int [2] p2c, c2p;
	    pipe2 (p2c.ptr, 0);
	    pipe2 (c2p.ptr, 0);
	    PipeContainer.instance.insertPipes (p2c, c2p);
	}
	
	foreach (it ; 0 .. nb) {
	    if (father) {
		auto id = fork ();	
		if (id == 0) { // Le fils		
		    PipeContainer.instance.thisId = it + 1;
		    father = false;
		} else
		    ids [it] = id;
	    }
	}
	
	if (!father) {
	    static if (is (ReturnType!fun : int))
		exit (fun (PipeContainer.instance.thisId, nb + 1));
	    else {
		fun (PipeContainer.instance.thisId, nb + 1);
		exit (0);
	    }
	}
	PipeContainer.instance.thisId = 0;
	return [thisId] ~ ids;
    }
    return [];
}

void join (uint [] ids) {
    if (ids.length > 0) {
	foreach (it ; ids [1 .. $]) {
	    auto stats = 0;
	    wait (it, &stats, 0);
	}
    }
}

void send (T...) (uint id, T msgs) {
    import std.format;
    if (thisId == id) assert (false,
			      format ("Send message to itself (%d)", id));
    else {
	auto pipe = PipeContainer.instance.write (id);
	flock (pipe, Locks.LOCK_EX);
	sendWPipe (pipe, msgs);
	flock (pipe, Locks.LOCK_UN);
    }
}

void sendToAll (T...) (uint id, uint total, T msgs) {
    foreach (it ; 0 .. total) {
	if (id != it) {
	    send (it, msgs);
	}
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
    write (pipe, cast (void*)elem.ptr, cast(int) (elem.length * U.sizeof));
}

void receive (T...) (ref T msg) {
    auto pipe = PipeContainer.instance.read (thisId);
    receiveWPipe (pipe, msg);    
}

T receive (T) () {
    T msg;
    auto pipe = PipeContainer.instance.read (thisId);
    receiveWPipe (pipe, msg);
    return msg;
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


uint countChild (uint id, uint total) @nogc {
    if (id >= total) return 0;
    else {
	return 1 +
	    countChild ((id * 2) + 1, total) +
	    countChild ((id * 2) + 2, total);
    }
}


auto cutInTwo (T) (T [] elem, uint to1, uint to2, uint total) @nogc {
    import std.typecons;
    if (elem.length == 0) return Tuple!(int[], int[])();
    else {
	auto nbChild1 = cast (float) countChild (to1, total);
	auto nbChild2 = cast (float) countChild (to2, total);
	auto sep = cast (ulong) (nbChild1 / (nbChild1 + nbChild2) * cast (float)elem.length);	
	return tuple(elem [0 .. sep], elem [sep .. $]);
    }
}

auto cutInThree (T) (T [] elem, uint id, uint total, ulong length) @nogc {
    import std.typecons, core.exception;
    T[][3] cut;
    
    auto to1 = (id * 2) + 1, to2 = (id * 2) + 2;
    
    if (to2 < total) {
	cut [0] = elem [0 .. (length / total)];
	auto res = cutInTwo (elem [(length / total) .. $], to1, to2, total);
	cut [1] = res [0];
	cut [2] = res [1];
    } else if (to1 < total) {
	cut [0] = elem [0 .. (length / total)];
	cut [1] = elem [(length / total) .. $];
	to2 = 0;
    } else {
	cut [0] = elem;
	to1 = to2 = 0;
    }	

    return tuple (to1, to2, cut);
}

void scatter (T) (uint id, uint total, ref T [] data) {
    int nb = 1;
    ulong length = data.length;
    if (total == 0) return;
    if (id == 0) {
	sendToAll (id, total, data.length);
    } else {
	receive (length);
    }
    
    T [] aux;
    if (id != 0) {
	receive (aux);
	auto res = cutInThree (aux, id, total, length);
	if (res [0] != 0) {
	    send (res [0], res [2][1]);
	}
	if (res [1] != 0) {
	    send (res [1], res [2][2]);
	}
	data = res [2][0];
    } else {
	aux = data;
	auto res = cutInThree (aux, id, total, length);
	if (res [0] != 0)
	    send (1, res [2][1]);
	if (res [1] != 0)
	    send (2, res [2][2]);
	data = res [2][0];
    }   
}



