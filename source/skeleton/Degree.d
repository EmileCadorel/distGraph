module skeleton.Degree;
import mpiez.admin, mpiez.Process;
import dgraph.DistGraph;


class Proto : Protocol {

    this (int id, int total) {
	super (id, total);
	this.msg = new Message!(1, ulong, ulong);
	this.info = new Message!(2, ulong);
    }

    Message!(1, ulong, ulong) msg;
    Message!(2, ulong) info;
    
}

ulong [ulong] sendAndRecv (DistGraph dg, ulong [ulong] values) {
    return null;
}

ulong [ulong] inDegree (DistGraph dg) {
    // On commence par calculer ce qu'on peut.
    ulong [ulong] res;
    foreach (et ; dg.edges) {
	res [et.dst] ++;
    }

    // Partie compliqué, il faut transmettre les infos au autres noeuds.
    res = sendAndRecv (dg, res);
    return res;
}

ulong [ulong] outDegree (DistGraph dg) {
    return null;
}

ulong [ulong] totalDegree (DistGraph dg) {
    return null;
}
