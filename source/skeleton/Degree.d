module skeleton.Degree;
import mpiez.admin, mpiez.Process;
import dgraph.DistGraph;
import skeleton.Zip;
import skeleton.MapReduceTriplets;

class Proto : Protocol {

    this (int id, int total) {
	super (id, total);
	this.msg = new Message!(1, ulong []);
	this.req = new Message!(2, byte);
    }

    Message!(1, ulong []) msg;
    Message!(2, byte) req;
    
}

private enum GET = 0;
private enum ZIP = 1;
private enum END = 2;


private ulong [] zipAll (T : DistGraph!(VD, ED), VD, ED) (T dg, ulong [] values) {
    auto info = Protocol.commInfo (MPI_COMM_WORLD);
    auto proto = new Proto (info.id, info.total);
    if (info.id == 0) {
	ulong [][] aux = new ulong[] [info.total];
	foreach (it ; 1 .. info.total) {	    
	    proto.req (it, GET);
	    proto.msg.receive (it, aux [it]);	   
	}

	auto total = values;
	foreach (it ; 1 .. info.total) {
	    total = Zip!((ulong i, ulong j) => i + j) (aux [it], total);
	}
	
	broadcast (0, total, MPI_COMM_WORLD);
	return total;
    } else {
	proto.msg (0, values);
	foreach (it ; 1 .. info.total)
	    Zip!((ulong i, ulong j) => i + j) ((ulong[]).init, (ulong[]).init);

	ulong [] res;
	broadcast (0, res, MPI_COMM_WORLD);
	return res;
    }    
}

ulong [] inDegree (T : DistGraph!(VD, ED), VD, ED) (T dg) {
    // On commence par calculer ce qu'on peut.
    ulong [] res = new ulong [dg.total];
	
    foreach (et ; dg.edges) {
	res [et.dst] ++;
    }

    // Partie compliqué, il faut transmettre les infos au autres noeuds.
    return zipAll (dg, res);
}

/**
 Cette fonction utilise un MapReduce mais est 30 fois plus lente.
 TODO, Optimiser le MapReduce
 */
int [ulong] inDegreeTest (T : DistGraph!(VD, ED), VD, ED) (T dg) {
    auto msgFun = (EdgeTriplet!(VD, ED) triplet) =>
	Iterator!(int) (triplet.dst.id, 1);

    auto reduceMsg = (int left, int right) => left + right;
    return dg.MapReduceTriplets!(msgFun, reduceMsg);
}

/**
 Cette fonction utilise un MapReduce mais est 30 fois plus lente.
 TODO, Optimiser le MapReduce
*/
int [ulong] outDegreeTest (T : DistGraph!(VD, ED), VD, ED) (T dg) {
    auto msgFun = (EdgeTriplet!(VD, ED) triplet) =>
	Iterator!(int) (triplet.src.id, 1);

    auto reduceMsg = (int left, int right) => left + right;
    return dg.MapReduceTriplets!(msgFun, reduceMsg);
}

ulong [] outDegree (T : DistGraph!(VD, ED), VD, ED) (T dg) {
    // On commence par calculer ce qu'on peut.
    ulong [] res = new ulong [dg.total];
	
    foreach (et ; dg.edges) {
	res [et.src] ++;
    }

    // Partie compliqué, il faut transmettre les infos au autres noeuds.
    return zipAll (dg, res);
}

ulong [] totalDegree (T : DistGraph!(VD, ED), VD, ED) (T dg) {
    // On commence par calculer ce qu'on peut.
    ulong [] res = new ulong [dg.total];
	
    foreach (et ; dg.edges) {
	res [et.src] ++;
	res [et.dst] ++;
    }

    // Partie compliqué, il faut transmettre les infos au autres noeuds.
    return zipAll (dg, res);
}