module mpiez.ezArray;
import mpi.mpi;
import std.conv;

int send (T : T[]) (int proc, int tag, T value, MPI_Comm comm) {
    return MPI_Send (value.ptr, to!int(value.length * T.sizeof), MPI_BYTE, proc, tag, comm);
}

int ssend (T : T []) (int proc, int tag, T value, MPI_Comm comm) {
    return MPI_Ssend (value.ptr, to!int(value.length * T.sizeof), MPI_BYTE, proc, tag, comm);
}

int recv (T : T[]) (int proc, int tag, ref T value, ref MPI_Status status, MPI_Comm comm) {
    int size;
    MPI_Probe (proc, tag, comm, &status);
    MPI_Get_count (&status, MPI_BYTE, &size);
    value.length = size / T.sizeof;
    return MPI_Recv (value.ptr, size, MPI_BYTE, proc, tag, comm, MPI_STATUS_IGNORE);
}


int sendRecv (T : T[]) (int to, int from, int tag, T to_send, ref T to_recv, ulong recvLength, ref MPI_Status status, MPI_Comm comm) {
    to_recv.length = recvLength;
    return MPI_Sendrecv (to_send.ptr, to!int(to_send.length * T.sizeof), MPI_BYTE, to, tag,
			 to_recv.ptr, to!int(recvLength * T.sizeof), MPI_BYTE, from, tag,
			 comm, &status);
}

int sendRecv (T : T []) (int to, int from, int tag, T to_send, ref T to_recv, ref MPI_Status status, MPI_Comm comm) {
    to_recv.length = to_send.length;
    return MPI_Sendrecv (to_send.ptr, to!int(to_send.length * T.sizeof), MPI_BYTE, to, tag,
			 to_recv.ptr, to!int(to_send * T.sizeof), MPI_BYTE, from, tag,
			 comm, &status);
}

int sendRecvReplace (T : T []) (int to, int from, int tag, ref T to_send, ref MPI_Status status, MPI_Comm comm) {
    return MPI_Sendrecv_replace (to_send.ptr, to!int(to_send.length * T.sizeof), MPI_BYTE,
				 to, tag,
				 from, tag,
				 comm, &status);
}


