module skeleton.Reverse;
import mpiez.admin;
import dgraph.DistGraph;

DistGraph!(VD, ED) Reverse (T : DistGraph!(VD, ED), VD, ED) (T dg) {
    auto aux = new DistGraph!(VD, ED) (dg.color, dg.nbColor);
    aux.total = dg.total;
    foreach (key, vt ; dg.vertices) {
	aux.addVertex (vt);
    }
    
    aux.edges = new EdgeD [dg.edges.length];
    foreach (it ; 0 .. dg.edges.length) {
	auto et = dg.edges [it];
	aux.edges [it] = (et.reverse);
    }
    return aux;
}
        
