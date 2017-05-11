module assign.socket.Package;
import std.socket;
import std.typecons;
import std.stdio;

/**
 System permettant l'enpaquetage des informations a transmettre par message
 */

void [] unpack (T) (void [] data_, ref T elem) {
    auto data = cast(byte[])(data_);
    elem = (cast (T*) data[0 .. T.sizeof]) [0];
    return data[T.sizeof .. data.length];    
}

void [] unpack (T : string) (void [] data_, ref T elem) {
    auto data = cast(byte[])data_;
    auto size = (cast(long*)data[0 .. 8])[0];
    data = data[8 .. data.length];
    for (int i = 0; i < size; i++) {
	elem ~= cast (char)data[i];
    }
    return data[size .. data.length];    
}

void [] unpack (T : T[]) (void [] data_, ref T [] elems) {
    ulong size;
    data_ = unpack (data_, size);
    elems.length = size;
    foreach (it ; 0 .. size) {
	data_ = unpack ! T (data_, elems[it]);
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

Tuple!(T, TArgs) fromArray (T : string, TArgs...) (void [] data) {
    T first;
    if (data.length != 0)
	data = unpack ! (T) (data, first);
    static if (TArgs.length > 0)
	return tuple(cast(T) first, fromArray ! TArgs (data).expand);
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

void enpack (T : string) (ref void [] data_, T elem) {
    auto data = cast(byte[])data_;
    auto begin = data.length;
    auto str = cast(byte[])((elem).dup);
    data.length += (str.length + 8);
    auto size = (cast(long*)(data[begin..(begin + 8)]));
    *size = str.length;
    for (ulong i = begin + 8; i < data.length; i++)
	data[i] = cast(byte)str[i - (begin + 8)];
    data_ = cast(void[])data;
}

void enpack (T) (ref void [] data_, T elem) {
    auto data = cast(byte[])data_;
    auto begin = data.length;
    data.length += T.sizeof;
    auto inside = cast(T*)data[begin .. (begin + T.sizeof)];
    *inside = elem;
    data_ = cast (void[]) data;
}

void enpack (T : T[]) (ref void[] data_, T [] elem) {
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
    
    this (TArgs ...) (TArgs elems) {
	this._data = enpack (elems);
    }

    static void [] enpack (TArgs...) (TArgs elems) {
	void [] datas;
	toArray ! TArgs (datas, elems);
	return datas;
    }
    
    static Tuple!(TArgs) unpack (TArgs...) (void [] data) {
	auto ret = fromArray!(TArgs) (data);
	return ret;
    }

    void [] data () {
	return this._data;
    }    
   
}
