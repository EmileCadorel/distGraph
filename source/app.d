import std.stdio;
import mpi.mpi;
import std.stdio;
import std.string;
import std.conv;

void main (string [] args) {
    MPI_Init(args);
    int my_rank = MPI_Comm_rank(MPI_COMM_WORLD);
    int size   = MPI_Comm_size(MPI_COMM_WORLD);
    
    string greeting = format("Hello world: processor %d of %d\n", my_rank, size);

    if (my_rank == 0) {
	writeln(greeting);
	for (int partner = 1; partner < size; partner++){  
	    MPI_Status stat;
	    MPI_Recv(cast(void*)greeting.ptr, to!int (greeting.length), MPI_BYTE, partner, 1, MPI_COMM_WORLD, &stat);
	    writeln(greeting);
	}
    } else {
	MPI_Send(cast(void*)greeting.ptr, to!int (greeting.length), MPI_BYTE, 0,1, MPI_COMM_WORLD);
    }
    
    MPI_Barrier (MPI_COMM_WORLD);
  
    if (my_rank == 0) writeln("That is all for now!\n");
    MPI_Finalize();  
}
