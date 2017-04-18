module skeleton.Reverse;
import mpiez.admin;
import dgraph.DistGraph;

DistGraph Reverse (DistGraph dg) {
    auto aux = new DistGraph (dg.color);
    foreach (key, vt ; dg.vertices) {
	aux.addVertex (vt);
    }
	
    foreach (it ; dg.edges) {
	aux.addEdge (Edge (it.dst, it.src, it.color));
    }
    return aux;
}
        
