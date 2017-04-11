module mpiez.ezList;
import mpi.mpi;
import std.container;

int send (T) (ref int proc, ref int tag, ref SList!T value, MPI_Comm comm) {
    auto vect = new T[value.length];
    ulong i = 0;
    foreach (it ; value) {
	vect [i] = it;
	i ++;
    }
    return MPI_Send (vect.ptr, vect.length * T.sizeof, MPI_BYTE, proc, tag, comm);
}

int recv (T) (ref int proc, ref int tag, ref SList!T value, ref MPI_Status status, MPI_Comm comm) {
    int size;
    MPI_Probe (proc, tag, comm, &status);
    MPI_Get_count (&status, MPI_BYTE, &size);
    auto aux = new T [size / T.sizeof];
    int i = MPI_Recv (aux.ptr, size, MPI_BYTE, proc, tag, comm, MPI_STATUS_IGNORE);
    value.clear ();
    foreach (it ; aux)
	value.insertFront (it);
    return i;
}
