module skeleton.Degree;
import mpiez.admin, mpiez.Process;
import dgraph.DistGraph;
import skeleton.Zip;
import skeleton.MapReduceTriplets;

class Proto : Protocol {

    this (int id, int total) {
	super (id, total);
	this.msg = new Message!(1, int []);
	this.req = new Message!(2, byte);
    }

    Message!(1, int []) msg;
    Message!(2, byte) req;
    
}

private enum GET = 0;
private enum ZIP = 1;
private enum END = 2;


private int [] zipAll (T : DistGraph!(VD, ED), VD, ED) (T dg, int [] values) {
    auto info = Protocol.commInfo (MPI_COMM_WORLD);
    auto proto = new Proto (info.id, info.total);
    if (info.id == 0) {
	int [][] aux = new int[] [info.total];
	foreach (it ; 1 .. info.total) {	    
	    proto.req (it, GET);
	    proto.msg.receive (it, aux [it]);	   
	}

	auto total = values;
	foreach (it ; 1 .. info.total) {
	    total = Zip!((int i, int j) => i + j) (aux [it], total);
	}
	
	broadcast (0, total, MPI_COMM_WORLD);
	return total;
    } else {
	proto.msg (0, values);
	foreach (it ; 1 .. info.total)
	    Zip!((int i, int j) => i + j) ((int[]).init, (int[]).init);

	int [] res;
	broadcast (0, res, MPI_COMM_WORLD);
	return res;
    }    
}

auto toAssoc (int [] _in) {
    int [ulong] _res;
    foreach (i, it ; _in)
	_res [i] = it;
    return _res;
}

/++
 Calcul le degrée entrants des sommets. (le sommets est la déstination de l'arête)
 Params:
 dg = un DistGraph, corrêctement répartie.
 Returns: un tableau associatif : degré [idSommet].
+/
auto inDegree (T : DistGraph!(VD, ED), VD, ED) (T dg) {
    // On commence par calculer ce qu'on peut.
    int [] res = new int [dg.total];
	
    foreach (et ; dg.edges) {
	res [et.dst] ++;
    }

    // Partie compliqué, il faut transmettre les infos au autres noeuds.
    return toAssoc (zipAll (dg, res));
}


/++
 Calcul le degrée entrants des sommets. (le sommets est la déstination de l'arête)
 Utilise le squelette  MapReduceTriplets
 Params:
 dg = un DistGraph, corrêctement répartie.
 Returns: un tableau associatif : degré [idSommet].
+/
int [ulong] inDegreeTest (T : DistGraph!(VD, ED), VD, ED) (T dg) {
    auto msgFun = (EdgeTriplet!(VD, ED) triplet) =>
	Iterator!(int) (triplet.dst.id, 1);

    auto reduceMsg = (int left, int right) => left + right;
    return dg.MapReduceTriplets!(msgFun, reduceMsg);
}

/++
 Calcul le degrée sortant des sommets. (le sommets est la source de l'arête)
 Utilise le squelette  MapReduceTriplets
 Params:
 dg = un DistGraph, corrêctement répartie.
 Returns: un tableau associatif : degré [idSommet].
+/
auto outDegreeTest (T : DistGraph!(VD, ED), VD, ED) (T dg) {
    auto msgFun = (EdgeTriplet!(VertexD, EdgeD) edge) =>
	Iterator!(int) (edge.src.id, 1);

    auto reduceMsg = (int left, int right) => left + right;
    return dg.MapReduceTriplets!(msgFun, reduceMsg);
}

/++
 Calcul le degrée sortant des sommets. (le sommets est la source de l'arête)
 Params:
 dg = un DistGraph, corrêctement répartie.
 Returns: un tableau associatif : degré [idSommet].
+/
auto outDegree (T : DistGraph!(VD, ED), VD, ED) (T dg) {
    // On commence par calculer ce qu'on peut.
    int [] res = new int [dg.total];
	
    foreach (et ; dg.edges) {
	res [et.src] ++;
    }

    // Partie compliqué, il faut transmettre les infos au autres noeuds.
    return toAssoc (zipAll (dg, res));
}

/++
 Calcul le degrée total des sommets. (le sommets est la source ou la destination de l'arête)
 Params:
 dg = un DistGraph, corrêctement répartie.
 Returns: un tableau associatif : degré [idSommet].
+/
auto totalDegree (T : DistGraph!(VD, ED), VD, ED) (T dg) {
    // On commence par calculer ce qu'on peut.
    int [] res = new int [dg.total];
	
    foreach (et ; dg.edges) {
	res [et.src] ++;
	res [et.dst] ++;
    }

    // Partie compliqué, il faut transmettre les infos au autres noeuds.
    return toAssoc (zipAll (dg, res));
}
