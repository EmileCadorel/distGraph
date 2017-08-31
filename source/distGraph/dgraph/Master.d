module distGraph.dgraph.Master;
import std.stdio;
import std.string, std.conv;
import distGraph.mpiez.Message, distGraph.mpiez.Process;
import distGraph.utils.Options;
import distGraph.dgraph.DistGraphLoader;
import distGraph.dgraph.Graph;
import distGraph.dgraph.DistGraph;
import std.container, std.array;

/++
 Classe instancié par DistGraphLoader
 Elle lis le fichier et répartie le travail entre les différents partitionner.
 C'est également elle qui récupère les informations de découpage et les envoie aux noeuds
+/
class Master {

    /++ 
     Le protocol utilisé entre les Slaves et le Master
     +/
    private Proto _proto;
    
    /++
     L'arête qui vient d'être lu et qui va être envoyé (peut être vide)
     +/
    private Edge _toSend;

    /++
     Le fichier en cours de lecture
     +/
    private File _file;

    /++
     Le nom du fichier en cours de lecture
     +/
    private string _filename;

    /++
     Le graphe qui sert de tampon pour les informations de partitions, de sommets et d'arêtes
     +/
    private Graph _current;

    /++
     On possède un arête à envoyer à un esclave ?
     +/
    private bool _read = true;

    /++
     La taille du fichier
     +/
    private ulong _length;

    /++
     Le pourcentage de lecture courant du fichier.
     +/
    private ulong _currentPercent;

    /++
     La partition du noeud maître
     +/
    private DistGraph!(VertexD, EdgeD) _dist;    
    
    /++
     Params:
     p = le protocol utilisé entre le maître et ses esclave
     filename = le nom du fichier à lire
     size = le nombre de partitions à créer (doit être = au nombre de noeud lancé par MPI)
     +/
    this (Proto p, string filename, ulong size) {
	this._proto = p;
	this._filename = filename;
	this._current = new Graph (size);
	this._dist = new DistGraph!(VertexD, EdgeD) (p.id, size);
    }

    /++
     Returns: le graphe tampon
     +/
    Graph graph () {
	return this._current;
    }

    /++
     Returns: la partitions créer par le découpage
     +/
    DistGraph!(VertexD, EdgeD) dgraph () {
	return this._dist;
    }

    /++
     Lis une arête dans le fichier
     Met this._read à vrai, si il a réussi, faux sinon
     +/
    private void _next () {
	import std.string;
	this._read = false;
	while (true) {
	    auto line = this._file.readln ();
	    if (line !is null) {
		line = line.stripLeft;
		if (line.length > 0 && line [0] != '#') {
		    auto nodes = line.split;
		    this._toSend.src = to!ulong (nodes [0]);
		    this._toSend.dst = to!ulong (nodes [1]);
		    this._read = true;
		    auto pos = this._file.tell ();
		    auto perc = to!int (to!float (pos) / to!float(this._length) * 100.);
		    if (perc > this._currentPercent) {
			this._currentPercent = perc;
			writef ("\rChargement du graphe %s>%s%d%c",
				leftJustify ("[", this._currentPercent, '='),
				rightJustify ("]", 100 - this._currentPercent, ' '),
				this._currentPercent, '%');
			stdout.flush;
		    }
		    break;
		}
	    } else break;	    
	}
    }

    /++
     Ouvre la fichier, met les informations de pourcentage et de taille à jour
     Returns: le fichier ouvert.
     +/
    private auto _open (string filename) {
	auto file = File (filename, "r");
	file.seek (0, SEEK_END);
	this._length = file.tell ();
	file.seek (0, SEEK_SET);
	return file;
    }

    /++
     Répartition des arêtes dans l'ordre d'apparition
     +/
    void runLinear () {
	this._file = this._open (this._filename);
	int nb = 0;
	while (this._read) {
	    this._next ();
	    if (this._read) {
		this._toSend.color = nb;
		this._current.addEdge (this._toSend);
		if (this._currentPercent >= (nb + 1) * 100 / this._proto.total) {
		    writeln ("Partition suivante");
		    nb ++;
		}
	    } else break;
	}
	distribute ();
	delete this._current;
	writeln ("\nFin de la distribution");
    }
    
    /++
     Routine de découpage
     Params:
     total = le nombre de worker.
     +/
    void run (ulong total) {
	this._file = this._open (this._filename);
	int nb = 0;
	while (nb < total) {	    
	    int type; ulong useless; byte uselessb;
	    auto status = this._proto.probe (MPI_ANY_SOURCE, MPI_ANY_TAG);
	    if (status.MPI_TAG == 1) { // Message request  (demande d'arête)
		this._proto.request.receive (status.MPI_SOURCE, uselessb);
		this._next ();
		if (this._read) { // On a reussi à lire, on envoie
		    Serializer!(Edge*) serial;
		    serial.value = &this._toSend;		    
		    this._proto.edge (status.MPI_SOURCE, serial.ptr, Edge.sizeof);
		} else { // aucune nouvelle arête, on informe le partitionner
		    this._proto.edge (status.MPI_SOURCE, null, 0);
		}		    
	    }  else if (status.MPI_TAG == 3) { // demande d'information sur l'état du graphe
		ulong [] vertices; // les identifiants des sommets questionnés
		this._proto.state.receive (status.MPI_SOURCE, vertices);
		computeState (status.MPI_SOURCE, vertices); // on envoie les infos
	    } else if (status.MPI_TAG == 5) { // Récéption des arêtes répartie par un partitionner
		Edge [] edges;
		this._proto.putState.receive (status.MPI_SOURCE, edges);
		foreach (it ; edges) // On les ajoute au tampon
		    this._current.addEdge (it);
	    } else if (status.MPI_TAG == 6) { // Le partitionner informe qu'il a finis son travail
		this._proto.end.receive (status.MPI_SOURCE, useless);
		nb ++;
	    } else assert (false, "Pas prevu ca"); // On recois un ordre inconnu
	}

	// Distribue le graphe tampon entre les différents noeuds
	distribute ();	
	delete this._current; // Supprime le graphe tampon (delete demande au GC de supprimer de manière immédiate)
	writeln ("\nFin de la distribution");
    }

    /++
     Distribution du graphe tampon entre les différents partitions (même celle qui ne partitionne pas)     
     +/
    private void distribute () {
	foreach (it; 0 .. this._current.vertices.length) {
	    if (it == 0) { // Ces sommets appartiennent au maître
		foreach (ref vt ; this._current.vertices [it])
		    this._dist.addVertex (vt);
	    } else { 
		long [] retVert; // sérialize les sommets à envoyer
		foreach (ref vt ; this._current.vertices [it]) retVert ~= vt.serialize ();
		this._proto.graphVert (cast (int) it, retVert);	// envoie les sommets à la bonne partitions	
	    }
	}

	foreach (it ; 0 .. this._current.edges.length) {
	    if (it == 0) { // Ces arêtes appartiennent au maître
		this._dist.setEdges(this._current.edges [it].array ());
	    } else { // Envoi des arête à la bonne partition
		this._proto.graphEdge (cast (int) it, this._current.edges [it].array ());
	    }
	}

	// On informe les noeuds que la répartition est bien finis, en leurs envoyant le nombre de sommets total du graphe
	foreach (it ; 0 .. this._proto.total) { 
	    this._proto.end (cast (int) it, this._current.verticesTotal.length); 
	}

	this._dist.total = this._current.verticesTotal.length;
    }

    /++
     Calcule un état en fonction d'une liste d'identifiants de sommets.
     Params:
     procId = l'id MPI du partitionner
     vertices = la liste des identifiants de sommets.
     +/
    private void computeState (int procId, ulong [] vertices) {
	long [] retVerts;
	foreach (it ; 0 .. vertices.length) { // on sérialize les sommets de l'état
	    retVerts ~= this._current.getVertex (vertices [it]).serialize ();
	}

	// On les envoi au partitionner en question
	this._proto.getState (procId, cast(ubyte*) retVerts.ptr, retVerts.length * long.sizeof , this._current.partitions);
    }

}
