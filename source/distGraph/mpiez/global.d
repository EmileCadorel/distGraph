module distGraph.mpiez.global;
import distGraph.mpi.mpi;
import std.typecons;

/++
 Enum utilisé pour le cartShift
+/
enum Shift : ubyte {
    VER = 0, HOR = 1
}

/++
 MPI_Barrier 
 Params:
 comm = le communicateur
+/
void barrier (MPI_Comm comm) {
    MPI_Barrier (comm);
}

/++
 Information sur la taille et l'index de debut d'un tableau global lors d'un scatter
 Params:
 size = la taille du tableau total
 id = l'identifiant du process
 nb_procs = le nombre de process 
 Returns: tuple (TailleLocal : 'len', IndexGlobal : 'begin')
+/
Tuple!(ulong, "len", ulong, "begin") computeLen (int size, int id, int nb_procs) {
    int n_s = size / nb_procs;
    int reste = size % nb_procs;
    int size_ = n_s;
    if (id < reste)
	return Tuple!(ulong, "len", ulong, "begin") (size_, size_ * id);
    else 
    	return Tuple!(ulong, "len", ulong, "begin") (size_, ((size_ + 1) * reste + ((id - reste) * size_)));
}

/++
 Scatter d'un tableau avec MPI_Scatter
 Params:
 root = le process root de l'échange
 size = la taille du tableau global
 _in = le tableau d'entré du scatter (vide ou null si !root)
 _out = le tableau qui va être rempli (il est alloué)
 comm = le communicateur utilisé
 Returns: l'index global de debut
+/
ulong scatter (T) (int root, int size, ref T [] _in, ref T [] _out, MPI_Comm comm) {
    int nb_procs, id;
    MPI_Comm_size (comm, &nb_procs);
    MPI_Comm_rank (comm, &id);
    int n_s = size / nb_procs;
    int reste = size % nb_procs;
    int [] ind, displs;
    if (id == root) {
	ind.length = nb_procs;
	displs.length = nb_procs;
	int disp = 0;
	foreach (it ; 0 .. ind.length) {
	    ind [it] = n_s * cast (int) T.sizeof;
	    if (it < reste) ind [it] += cast (int) T.sizeof;
	    displs [it] = disp;
	    disp += ind [it];
	}
    }

    int size_ = n_s;
    if (id < reste) size_ += 1;
    _out.length = size_;
    MPI_Scatterv (_in.ptr, ind.ptr, displs.ptr, MPI_BYTE, _out.ptr, size_ * cast (int)T.sizeof, MPI_BYTE, root, comm);

    if (id < reste) {
	return (size_ * id);
    } else {
	return ((size_ + 1) * reste + ((id - reste) * size_));
    }    
}

/++
 Broadcast une valeur sur un communicateur
 Params:
 root = l'identifiant du process root de l'échange
 _in = la valeur à envoyer (par ref pour !root)
 comm = le communicateur à utiliser
+/
void broadcast (T) (int root, ref T _in, MPI_Comm comm) {
    MPI_Bcast (&_in, T.sizeof, MPI_BYTE, root, comm);
}

/++
 Broadcast d'un tableau sur un communicateur
 Params:
 root = l'identifiant du process root de l'échange
 _in = la valeur à envoyer (par ref et alloué si !root)
 comm = le communicateur à utiliser
+/
void broadcast (T : U [], U) (int root, ref T _in, MPI_Comm comm) {
    import mpiez.Process;
    auto info = Protocol.commInfo (comm);
    auto len = _in.length;
    broadcast (root, len, comm);
    if (info.id != root) {
	_in = new U [len];
    }
    MPI_Bcast (_in.ptr, cast (int) (len * U.sizeof), MPI_BYTE, root, comm);	
}

/++
 Fonction impossible (static asser)t
+/
void scatter (T) (int root, int size, ref T [][] _in, ref T [][] _out, MPI_Comm comm) {
    static assert ("Scatter on mutiple vector");
}

/++
 Fonction impossible (static asser)t
+/
void scatterNxM (T) (int root, int n, int m, ref T [][] _in, ref T [][] _out, MPI_Comm comm) {
    static assert ("Scatter on mutiple vector");
}

/++
 Scatter d'un matrice
 Params:
 root = l'identifiant du process root de l'échange
 n = la taille en lignes de la matrice
 m = la taille en colonnes de la matrice
 _in = la matrice (null ou vide si !root)
 _out = la matrice généré (alloué dans la fonction)
 comm = le communicateur
+/
void scatterNxM (T) (int root, int n, int m, ref T [] _in, ref T [] _out, MPI_Comm comm) {
    int nb_procs, id;
    MPI_Comm_size(comm, &nb_procs);
    MPI_Comm_rank(comm, &id);
    int n_s = n / nb_procs;
    int reste = n % nb_procs;

    int [] ind, displs;
    if(id == root) {
		
	ind.length = nb_procs;
	displs.length = nb_procs;

	int disp = 0;
	for(int i = 0; i < ind.size(); i++) {
	    ind[i] = n_s * T.sizeof * m;
	    if(i < reste) ind[i] += T.sizeof * m;
	    displs[i] = disp;
	    disp += ind[i];
	}
    }
	    
    int size_ = n_s * m;
    if(id < reste) size_ += m;    
	    	    
    _out.length = size_;

    MPI_Scatterv(_in.ptr, ind.ptr, displs.ptr, MPI_BYTE, _out.ptr, size_ * T.sizeof, MPI_BYTE, root, comm);
}

/++
 Gather d'un tableau
 Params:
 root = l'identifiant du process root de l'échange
 size = la taille du tableau final
 _in = le tableau d'entré
 _out = le tableau final (alloué si root)
 comm = le communicateur
+/
void gather (T : U [], U)(int root, int size, ref T _in, ref T _out, MPI_Comm comm) if (!is (U : Object)) {
    int nb_procs, id;
    MPI_Comm_size(comm, &nb_procs);
    MPI_Comm_rank(comm, &id);
    int n_s = size / nb_procs;
    int reste = size % nb_procs;
    int [] ind, displs;
    if(id == root) {
	ind.length = (nb_procs);
	displs.length = (nb_procs);
	
	int disp = 0;
	for(int i = 0; i < ind.length; i++) {
	    ind[i] = n_s * cast (int) U.sizeof;
	    if(i < reste) ind[i] += cast (int) U.sizeof;
	    displs[i] = disp;
	    disp += ind[i];
	}
	_out.length = (size);
    }
    
    MPI_Gatherv(_in.ptr, cast (int) (_in.length * U.sizeof), MPI_BYTE, _out.ptr, ind.ptr, displs.ptr, MPI_BYTE, root, comm);
}


/++
 Gather d'un tableau à partir de valeur unique 
 Params:
 root = l'identifiant du process root de l'échange
 size = la taille du tableau final
 _in = la valeur d'entrée
 _out = le tableau final (alloué si root)
 comm = le communicateur
+/
void gather (T : U [], U) (int root, int size, ref U _in, ref T _out, MPI_Comm comm) if (!is (U : Object)) {
    int nb_procs, id;
    MPI_Comm_size(comm, &nb_procs);
    MPI_Comm_rank(comm, &id);
    int n_s = size / nb_procs;
    int reste = size % nb_procs;
    int [] ind, displs;
    if(id == root) {
	ind.length = (nb_procs);
	displs.length = (nb_procs);
	
	int disp = 0;
	for(int i = 0; i < ind.length; i++) {
	    ind[i] = n_s * cast (int) U.sizeof;
	    if(i < reste) ind[i] += cast (int)U.sizeof;
	    displs[i] = disp;
	    disp += ind[i];
	}
	_out.length = (size);
	
    }
    
    MPI_Gatherv(&_in, cast (int) (U.sizeof), MPI_BYTE, _out.ptr, ind.ptr, displs.ptr, MPI_BYTE, root, comm);
}

void dimsCreate(int total, int nb_dim, int [2] size) {
    MPI_Dims_create(total, nb_dim, size.ptr);
}

void cartCreate(MPI_Comm comm, int nb_dim, int [2] size, int [2] periodics, int reorder, ref MPI_Comm out_comm) {
    MPI_Cart_create(comm, nb_dim, size.ptr, periodics.ptr, reorder, &out_comm);
}

void cartCoords(MPI_Comm comm, int pid, int nb_dims, int [2] coords) {
    MPI_Cart_coords(comm, pid, nb_dims, coords.ptr);
}

void cartCoords(MPI_Comm comm, int pid, int nb_dims, ref int []coords) {
    coords.length = 2;
    MPI_Cart_coords(comm, pid, nb_dims, coords.ptr);
}

void cartShift (MPI_Comm comm, Shift type, int nb, ref int src, ref int dest) {
    MPI_Cart_shift (comm, type, nb, &src, &dest);
}

/++
 Fonction appelé de manière synchrone entre les process MPI (tout les process du communicateur doivent l'appler)
 Params:
 comm = le communicateur
 f = la fonction a appelé
 param = les paramètres à passer à la fonction 
+/
void syncFunc (Foo : void function (Params), Params ...) (MPI_Comm comm, Foo f, ref Params param) {
    int id, size;
    MPI_Comm_rank (comm, &id);
    MPI_Comm_size (comm, &size);
    foreach (it ; 0 .. size) {
	if (id == i)
	    f (param);
	barrier (comm);
    }
    barrier (comm);
}


/++
 Fonction appelé de manière synchrone entre les process MPI (tout les process de MPI_COMM_WORLD doivent l'appler)
 Params:
 f = la fonction a appelé
 param = les paramètres à passer à la fonction 
+/
void syncFunc (Foo : void function (Params), Params ...) (Foo f, Params param) {
    int id, size;
    MPI_Comm_rank (MPI_COMM_WORLD, &id);
    MPI_Comm_size (MPI_COMM_WORLD, &size);
    foreach (it ; 0 .. size) {
	if (id == it)
	    f (param);
	barrier (MPI_COMM_WORLD);
    }
    barrier (MPI_COMM_WORLD);
}

/++
 Appel synchrone de la fonction writeln (...); sur MPI_COMM_WORLD
 Params:
 params = les paramètres a passer à writeln.
+/
void syncWriteln (T ...) (T params) {
    import std.stdio;
    int id, size;
    MPI_Comm_rank (MPI_COMM_WORLD, &id);
    MPI_Comm_size (MPI_COMM_WORLD, &size);
    foreach (it ; 0 .. size) {
	if (id == it)
	    writeln (id, " => [", params, "]");
	barrier (MPI_COMM_WORLD);
    }
    barrier (MPI_COMM_WORLD);
}


/++
 Appel synchrone de la fonction writeln (...); 
 Params:
 comm = le communicateur
 params = les paramètres a passer à writeln.
+/
void syncWriteln (Fst : MPI_Comm, T ...) (Fst comm, T params) {
    import std.stdio;
    int id, size;
    MPI_Comm_rank (comm, &id);
    MPI_Comm_size (comm, &size);
    foreach (it ; 0 .. size) {
	if (id == it)
	    writeln (id, " => [", params, "]");
	barrier (comm);
    }
    barrier (comm);
}

/++
 Appel synchrone de la fonction writeln (...); avec un fonction de map.
 Params:
 fun = la fonction de map.
 param = les paramètres à passer
 comm = le communicateur
+/
void syncWriteln (alias fun, T : U [], U) (T param, MPI_Comm comm = MPI_COMM_WORLD) {
    import std.stdio, std.traits;
    int id, size;
    MPI_Comm_rank (comm, &id);
    MPI_Comm_size (comm, &size);
    foreach (it ; 0 .. size) {
	if (id == it) {
	    write (id, " => [");
	    alias FP = ParameterTypeTuple!(fun);
	    static if (FP.length == 2) {
		foreach (i, pt ; param)
		    write (fun (i, pt));
	    } else {
		foreach (pt ; param)
		    write (fun (pt));
	    }
	    writeln ("]");
	}
	barrier (comm);
    }
    barrier (comm);
}

/++
 Appel synchrone de la fonction writeln (...); avec un fonction de map sur un tableau associatif.
 Params:
 fun = la fonction de map.
 param = les paramètres à passer
 comm = le communicateur
+/
void syncWriteln (alias fun, T : U [V], U, V) (T param, MPI_Comm comm = MPI_COMM_WORLD) {
    import std.stdio;
    int id, size;
    MPI_Comm_rank (comm, &id);
    MPI_Comm_size (comm, &size);
    foreach (it ; 0 .. size) {
	if (id == it) {
	    write (id, " => [");
	    foreach (key, value ; param)
		write (fun (key, value));
	    writeln ("]");
	}
	barrier (comm);
    }
    barrier (comm);
}



