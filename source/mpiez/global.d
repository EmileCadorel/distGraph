module mpiez.global;
import mpi.mpi;

enum Shift : ubyte {
    VER = 0, HOR = 1
}

void barrier (MPI_Comm comm) {
    MPI_Barrier (comm);
}

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

void scatter (T) (int root, int size, ref T [][] _in, ref T [][] _out, MPI_Comm comm) {
    static assert ("Scatter on mutiple vector");
}

void scatterNxM (T) (int root, int n, int m, ref T [][] _in, ref T [][] _out, MPI_Comm comm) {
    static assert ("Scatter on mutiple vector");
}

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
	
void gather (T : U [], U)(int root, int size, ref T _in, ref T _out, MPI_Comm comm) {
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

void gather (T : U [], U) (int root, int size, ref U _in, ref T _out, MPI_Comm comm) {
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



void reduce (T) (int root, int size, ref T [] _in, ref T [] _out, MPI_Datatype type, MPI_Op op, MPI_Comm comm) {
    int id;
    MPI_Comm_rank(comm, &id);
    if(id == root) {
	_out.length = (_in.size());
    }
    
    MPI_Reduce(_in.ptr, _out.ptr, size, type, op, root, comm);  
}
	

void allReduce (T) (int size, ref T [] _in, ref T [] _out, MPI_Datatype type, MPI_Op op, MPI_Comm comm) {
    _out.length = (_in.size());
    MPI_Allreduce(_in.ptr, _out.ptr, size, type, op, comm);  
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

