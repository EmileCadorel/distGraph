module mpiez.ezBase;
import mpi.mpi;
import std.string, std.conv;

int send (A) (int proc, int tag, A value, MPI_Comm comm) {
    return MPI_Send (&value, value.sizeof, MPI_BYTE, proc, tag, comm);
}

int ssend (A) (int proc, int tag, A value, MPI_Comm comm) {
    return MPI_Ssend (&value, value.sizeof, MPI_BYTE, proc, tag, comm);
}

int send (int proc, int tag, string value, MPI_Comm comm) {
    import std.string, std.conv;
    return MPI_Send (to!(char[])(value).ptr, to!int(value.length), MPI_CHAR, proc, tag, comm);
}

int ssend (int proc, int tag, string value, MPI_Comm comm) {
    return MPI_Ssend (to!(char[])(value).ptr, to!int(value.length), MPI_CHAR, proc, tag, comm);
}

int recv (A) (int proc, int tag, ref A value, ref MPI_Status status, MPI_Comm comm) {
    return MPI_Recv (&value, A.sizeof, MPI_BYTE, proc, tag, comm, &status);
}

int recv (int proc, int tag, ref string value, ref MPI_Status status, MPI_Comm comm) {
    int size;
    MPI_Probe (proc, tag, comm, &status);
    MPI_Get_count (&status, MPI_CHAR, &size);
    char [] buf = new char [size];
    int i = MPI_Recv (buf.ptr, size, MPI_CHAR, proc, tag, comm, &status);
    value = to!string (buf);
    return i;
}

int sendRecv (A, B) (int to, int from, int tag, A to_send, ref B to_recv, ref MPI_Status status, MPI_Comm comm) {
    return MPI_Sendrecv (&to_send, A.sizeof, MPI_BYTE, to, tag,
			 &to_recv, B.sizeof, MPI_BYTE, from, tag,
			 comm, &status);
}

int sendRecv (int to_, int from, int tag, string to_send, ref string to_recv, ulong recvLength, ref MPI_Status status, MPI_Comm comm) {
    auto recv = new char [recvLength];
    int i = MPI_Sendrecv (to!(char[])(to_send).ptr, cast(int) (to_send.length), MPI_CHAR, to_, tag,
			  recv.ptr, cast (int) (recvLength), MPI_CHAR, from, tag,
			  comm, &status);
    to_recv = to!string (recv);
    return i;
}

int sendRecvReplace (A) (int to, int from, int tag, ref A to_send, ref MPI_Status status, MPI_Comm comm) {
    return MPI_Sendrecv_replace (&to_send, A.sizeof, MPI_BYTE, to, tag, from, tag, comm, &status);
}

int sendRecvReplace (int to_, int from, int tag, ref string to_send, ref MPI_Status status, MPI_Comm comm) {
    return MPI_Sendrecv_replace (to!(char [])(to_send).ptr, to!int (to_send.length), MPI_CHAR, to_, tag, from, tag, comm, &status);
}



