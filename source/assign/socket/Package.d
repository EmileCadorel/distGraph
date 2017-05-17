module assign.socket.Package;
import std.socket;
import std.typecons;
import std.traits;
import std.stdio;

/**
 System permettant l'enpaquetage des informations a transmettre par message
 */

void [] unpack (T) (void [] data_, ref T elem) if (isBasicType!(T)) {
    auto data = cast(byte[])(data_);
    elem = (cast (T*) data[0 .. T.sizeof]) [0];
    return data[T.sizeof .. data.length];    
}

void [] unpack(T : U[], U) (void [] data_, ref T  elems) if (isBasicType!(U)) {
    auto data = cast (byte[])data_;
    auto size = *(cast (ulong*) data [0 .. ulong.sizeof]);
    elems = new U [size];
    auto aux = data [ulong.sizeof .. ulong.sizeof + size * U.sizeof];
    elems = cast (U[]) aux;
    
    /*foreach (it; 0 .. elems.length) {
	auto index = (ulong.sizeof + U.sizeof * it);
	elems [it] = *(cast (U*) data [index .. index + U.sizeof]);
	}*/
    return cast (void[]) (data [(ulong.sizeof + size * U.sizeof) .. $]);
 }

void [] unpack (T : U[], U) (void [] data_, ref T elems) if (!isBasicType!(U)) {
    ulong size;
    data_ = unpack (data_, size);
    elems.length = size;
    foreach (it ; 0 .. size) {
	data_ = unpack ! U (data_, elems[it]);
    }
    return data_;
}

void [] unpack (U, T : T[U])(void [] data_, ref T[U] elems) {
    ulong size;
    data_ = unpack (data_, size);
    foreach (it ; 0 .. size) {
	U elem;	
	data_ = unpack ! U (data_, elem);
	T value;
	data_ = unpack ! T (data_, value);
	elems[elem] = value;
    }
    return data_;
}

Tuple!(T, TArgs) fromArray(T : T[U], U, TArgs...) (void [] data) {
    T first;
    if (data.length != 0)
	data = unpack ! (U, T[U]) (data, first);
    static if (TArgs.length > 0)
	return tuple(first, fromArray ! TArgs (data).expand);
    else
	return tuple(first);
}

Tuple!(T, TArgs) fromArray (T : U[], U, TArgs...) (void [] data) {
    T first;
    if (data.length != 0)
	data = unpack ! (T) (data, first);
    static if (TArgs.length > 0)
	return tuple(cast(T) first, fromArray ! TArgs (data).expand);
    else
	return tuple(first);
}

Tuple!(T, TArgs) fromArray(T, TArgs...) (void [] data) {
    T first;
    if (data.length != 0) 
	data = unpack ! T (data, first);
    static if (TArgs.length > 0)
	return Tuple!(T, TArgs)(first, fromArray ! TArgs (data).expand);
    else
	return tuple(first);
}

void enpack (T) (ref void [] data_, T elem) {
    auto data = cast(byte[])data_;
    auto begin = data.length;
    data.length += T.sizeof;
    auto inside = cast(T*)data[begin .. (begin + T.sizeof)];
    *inside = elem;
    data_ = cast (void[]) data;
}

void enpack (T : U[], U) (ref void [] data_, T elem) if (isBasicType!(U)) {
    auto data = cast (byte[])data_;
    auto begin = data.length;
    
    data.length += ulong.sizeof;
    auto inside = cast (ulong*)data [begin .. (begin + ulong.sizeof)];    
    *inside = elem.length;
    
    data_ = cast (void[])(data ~ cast(byte[])(elem));
 }


void enpack (T : T[]) (ref void[] data_, T [] elem) if (!isBasicType!(T)) {
    enpack (data_, elem.length);
    foreach (it ; 0 .. elem.length)
	enpack ! T (data_, elem[it]);
}

void enpack (U, T : T[U]) (ref void [] data_, T [U] elem) {
    enpack (data_, elem.length);
    foreach (key, value ; elem) {
	enpack ! U (data_, key);
	enpack ! T (data_, value);
    }
}

void toArray (T : T[U], U, TArgs...) (ref void [] data, T[U] first, TArgs next) {
    enpack ! (U, T[U]) (data, first);
    toArray ! TArgs (data, next);
}

void toArray (T, TArgs...) (ref void [] data, T first, TArgs next) {
    enpack ! T (data, first);
    toArray ! TArgs (data, next);
}

void toArray () (ref void[]) {}

class Package {

    private void [] _data;

    this (void [] data) {
	this._data = data;
    }
    
    this (TArgs ...) (TArgs elems) {
	toArray !TArgs (this._data, elems);
    }

    static bool isSimplePack (TArgs...) () {
	bool simple = true;
	foreach (i, it ; TArgs) {
	    static if (!isBasicType !(it) && !is (it : string)) {	
		static if (isArray!(it)) {
		    static if (!(is (it u : U[], U) && isBasicType !(U))) {
			simple = false;
			break;
		    } else continue;
		} else {
		    simple = false;
		    break;
		}
	    }
	}
	return simple;
    }
    
    static Package enpack (TArgs...) (TArgs elems) {       
	static if (isSimplePack !(TArgs)) {
	    return new PackageS!(TArgs) (elems);
	} else {	    
	    static if (TArgs.length == 1 && is (TArgs[0] : U[], U)) {
		auto ret = cast (byte[])(elems [0]);
		return new Package (ret);
	    } else {
		void [] datas;
		toArray ! TArgs (datas, elems);
		return new Package (datas);	    
	    }
	}
    }
    
    static Tuple!(TArgs) unpack (TArgs...) (void [] data) {
	auto ret = fromArray!(TArgs) (data);
	return ret;	
    }

    static T get (T) (ref void [] data) {
	return fromArray!(T) (data) [0];
    }
    
    void [] data () {
	return this._data;
    }    

    void send (Socket sock) {
	assert (false);
    }

    bool isSimple () {
	return false;
    }
    
}


class PackageS (TArgs ...) : Package {

    private Tuple!(TArgs) _data;
    
    private ulong _len;
    
    this (TArgs elems) {
	this._data = tuple(elems);
	foreach (it ; elems) {
	    static if (isBasicType !(typeof (it))) 
		this._len += it.sizeof;
	    else static if (is (typeof (it) u : U[], U)) 
		this._len += U.sizeof * it.length + 8;	
	}
    }

    override void send (Socket sock) {
	sock.send ([this._len]);
	foreach (it ; this._data) {
	    static if (!isArray!(typeof (it))) {
		sock.send ([it]);
	    } else {
		auto toSend = cast(byte[]) it;
		sock.send ([it.length]);
		sock.send (toSend);
	    }
	}
    }
    
    override bool isSimple () {
	return true;
    }
    
}
