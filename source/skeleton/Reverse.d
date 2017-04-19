module skeleton.Reverse;
import mpiez.admin;
import dgraph.DistGraph;

DistGraph Reverse (DistGraph dg) {
    auto aux = new DistGraph (dg.color, dg.nbColor);
    aux.total = dg.total;
    foreach (key, vt ; dg.vertices) {
	aux.addVertex (vt);
    }

    aux.edges = new Edge [dg.edges.length];
    foreach (it ; 0 .. dg.edges.length) {
	auto et = dg.edges [it];
	aux.edges [it] = (Edge (et.dst, et.src, et.color));
    }
    return aux;
}
        
