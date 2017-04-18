module dgraph.Vertex;
import dgraph.Edge, dgraph.Graph;
import std.container;
import std.outbuffer;
import std.traits;
import utils.Colors, dgraph.Partition;


struct Vertex {
    ulong id;

    ulong degree;
    
    long [] partitions;

    bool isInPartition (ulong id) {
	import std.algorithm;
	return find!("a == cast(long)b") (partitions [], id).length > 0;
    }

    bool addPartition (ulong id) {
	foreach (ref it ; this.partitions) {
	    if (it == id) return false;
	    else if (it == -1) {
		it = id;
		return true;
	    }
	}
	assert (false, "Trop de découpage");
    }

    long [] serialize () {
	return (cast (long[]) ([this.id, this.degree, partitions.length])) ~ partitions;
    }
    
    static Vertex deserialize (ref ubyte * val, ref ulong len) {
	Vertex v;
	auto value = cast (ulong*) val;
	v.id = *(value);
	v.degree = *(value + 1);
	auto parts = cast (long*) (value + 2);
	auto nb = *parts;
	v.partitions = new long [nb];
	foreach (it ; 0 .. nb) {
	    v.partitions [it] = *(parts + it + 1);
	}
	
	auto aux = cast (ubyte*) (parts + nb + 1);
	len -= aux - val;
	val = aux;
	return v;
    }
    
}
