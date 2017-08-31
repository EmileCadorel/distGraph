module distGraph.dgraph.Slave;
import std.stdio;
import std.string, std.conv;
import distGraph.mpiez.Message, distGraph.mpiez.Process;
import distGraph.utils.Options;
import distGraph.dgraph.DistGraphLoader;
import distGraph.dgraph.Edge, distGraph.dgraph.Vertex;
import std.container, std.array;
import distGraph.dgraph.DistGraph;

/++
 Recherche un extreme en fonction d'un prédicat.
 Normalement, minElement, et maxElement sont dans la std mais pas pour gdc.
 Params:
 fun = le prédicat
 T = le type d'élément du tableau
 rng = le tableau à analyser
 Returns: l'extreme du tableau selon fun.
+/
T findExtrem (alias fun, T) (T [] rng) {
    T ret = rng [0];
    foreach (it ; 1 .. rng.length) {
	if (fun (rng [it], ret)) ret = rng [it];
    }
    return ret;
}

/++
 Classe de partitionnement du graphe, récupère des arêtes auprès de Master et les associent à une partitions.
+/
class Slave {

    /++
     Protocol partagé avec le master.
     +/
    private Proto _proto;

    /++
     la condition d'arret de la routine
     +/
    private bool _end = false;

    /++
     La fenêtre des arêtes en cours de lecture
     +/
    private Array!Edge _window;

    /++
     Les identifiants de sommets découvert dans la fenêtre d'arête.
     +/
    private Array!ulong _vertices;

    /++
     Le paramètre de l'heuristique.
     +/
    private static float __lambda__;

    /++
     La partitions créer pour le noeud.
     +/
    private DistGraph!(VertexD, EdgeD) _dist;    

    /++
     Params:
     p = le protocol 
     lambda = le paramètre de l'heuristique
     +/
    this (Proto p, float lambda) {
	this._proto = p;
	__lambda__ = lambda;
	this._dist = new DistGraph!(VertexD, EdgeD) (p.id, p.total);
    }


    /++
     Returns: l'instance distribué du graphe.
     +/
    DistGraph!(VertexD, EdgeD) dgraph () {
	return this._dist;
    }

    /++
     La routine de partitionnement
     +/
    void run () {
	while (!this._end) {
	    this._proto.request (0, EDGE); // On demande un arête	   
	    this._proto.edge.receive (0, &this.edgeReceived);
	    if (!this._end && this._window.length % WINDOW_SIZE == 0) { // On a assez d'arête on partitionne
		partitionWindow ();
		this._window.clear ();
		this._vertices.clear ();
	    } else if (this._end && this._window.length > 0) { // On a rien reçu mais il reste des arête à partitionner
		partitionWindow ();
		this._window.clear ();
		this._vertices.clear ();
	    }	    
	}
	// On informe le maître qu'on a finis
	this._proto.end (0, END);
	waitGraph ();
    }

    /++
     On attend les informations de notre partition
     +/
    void waitGraph () {
	while (true) {
	    auto status = this._proto.probe ();
	    if (status.MPI_TAG == this._proto.end.TAG) { // Le maître a tout dis on quitte
		ulong len; // Le nombre de sommets dans le graphe total
		this._proto.end.receive (0, len); 
		this._dist.total = len; 
		break;
	    } else if (status.MPI_TAG == this._proto.graphVert.TAG) { // Recéption de sommets
		this._proto.graphVert.receive (0, &this.graphVertRec);
	    } else { // Récéption d'arêtes.
		this._proto.graphEdge.receive (0, &this.graphEdgeRec);
	    }
	}
    }

    /++
     Partitionnement des arêtes qui sont dans la fenêtre.
     +/
    private void partitionWindow () {
	this._proto.state (0, (this._vertices.array));
	Vertex [] vertices; ulong [] partitions;
	stateReceive (vertices, partitions); // On récupère l'état du graphe
	for (int it = 0, vt = 0; it < this._window.length; it ++, vt += 2) { 
	    auto u = vertices [vt];
	    auto v = vertices [vt + 1];
	    u.degree ++; // Mise à jour des degrés des sommets
	    v.degree ++;
	    auto p = selectPartitionHDRF (u, v, partitions); // On choisit une partition à associer
	    this._window [it].color = p; // On l'applique à l'arête.
	}
	this._proto.putState (0, (this._window.array)); // On envoie le découpage au maître.
    }

    /++
     Calcul du score de répartition (égalité des tailles des partitions)
     +/
    private float balanceScoreHDRF (ulong p, ulong max, ulong min, float lambda, float epsilon) {
	return lambda * (cast (float) max - cast (float) p) /
	    (epsilon + cast (float) max - cast (float) min);
    }

    /++
     Score de réplication d'un sommet.
     +/
    private float g (Vertex v, ulong p, float thetaV) {
	if (!v.isInPartition(p))
	    return 0;
	else return 1 + (1 - thetaV);
    }

    /++
     Score de réplication des sommets source et destiniation 
     +/
    private float replicationScoreHDRF (Vertex u, Vertex v, ulong p, float thetaV1, float thetaV2) {
	return g (u, p, thetaV1) + g (v, p, thetaV2);
    }

    /++
     On choisit une partition en fonction de l'heuristique HDRF
     Params:
     u = un sommet de l'arête (l'arête ici n'est plus orienté)
     v = un sommet de l'arête
     partitions = la taille des partitions de l'état courant du graphe.
     +/
    private ulong selectPartitionHDRF (Vertex u, Vertex v, ulong [] partitions) {
	import std.algorithm, std.typecons, std.math;
	alias Pair = Tuple!(ulong, "p", float, "score");
	float epsilon = 3.;	    
	auto delta1 = u.degree, delta2 = v.degree;
	auto thetaV1 = cast (float) delta1 / cast (float) (delta1 + delta2);
	auto thetaV2 = 1 - thetaV1;
	auto maxP = partitions.findExtrem!((a, b) => a > b); // On récupère la partition la plus grande
	auto minP = partitions.findExtrem!((a, b) => a < b); // On récupère la partition la plus petite
	Pair maxPart = Pair (0, float.init);
	Pair [] scores = new Pair [partitions.length];
	foreach (it ; 0 .. partitions.length) {
	    auto p = partitions [it];
	    auto rScore = replicationScoreHDRF (u, v, it, thetaV1, thetaV2);
	    auto bScore = balanceScoreHDRF (p, maxP, minP, __lambda__, epsilon);
	    scores [it] = Pair (it, (rScore + bScore) / 2.);
	}
	// On récupère la partition qui a le meilleur score.
	return scores [].findExtrem!((a, b) => a.score > b.score).p;
    }    

    /++
     On reçoit une arête
     Params:
     test = le pointeur vers les données
     len =  la taille des données
     +/
    private void edgeReceived (ubyte * test, ulong len) {
	if (len != 0) { // On a bien une arête
	    Serializer!(Edge*) serial;
	    serial.ptr = test;
	    this._window.insertBack (*serial.value);
	    this._vertices.insertBack (serial.value.src);
	    this._vertices.insertBack (serial.value.dst);
	} else {
	    this._end = true; // Pas d'arête on stop le travail.
	}
    }    

    /++
     Récéption des sommets de la partitions.
     Params:
     vertices = les sommets sérialiser
     +/
    private void graphVertRec (long [] vertices) {
	auto begin = cast (ubyte*)vertices.ptr;
	auto len = vertices.length * long.sizeof;
	while (len > 0) { // On désérialise les sommets et on les ajoute à la partitions.
	    this._dist.addVertex (Vertex.deserialize (begin, len));
	}
    }

    /++
     Récéption des arêtes de la partition
     Params:
     edges = les arêtes à mettre dans la partition.
     +/
    private void graphEdgeRec (Edge [] edges) {	
	this._dist.setEdges(edges);
    }

    /++
     Récéption de l'état courant du graphe.
     +/
    private void stateReceive (ref Vertex [] vertices, ref ulong [] partitions) {
	ubyte * begin;
	ulong len;
	this._proto.getState.receive (0, begin, len, partitions); 
	while (len > 0) { // On désérialise les données reçu.
	    vertices ~= Vertex.deserialize (begin, len);
	}
    }
    
}
