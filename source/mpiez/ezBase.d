module mpiez.ezBase;
import mpi.mpi;
import std.string, std.conv;
import std.traits;

/++
 Ce fichier contient toutes les fonctions nécéssaire à la communication point à point.
+/


/++
 Envoi d'un message par MPI_Send
 Params:
 proc = l'identifiant du process cible
 tag = le tag du message
 value = la valeur à envoyer
 comm = le communicateur utilisé pour le message.
 Returns: l'information de succès.
+/
int send (A) (int proc, int tag, A value, MPI_Comm comm) {
    return MPI_Send (&value, value.sizeof, MPI_BYTE, proc, tag, comm);
}

/++
 Envoi d'un message par MPI_Ssend
 Params:
 proc = l'identifiant du process cible
 tag = le tag du message
 value = la valeur à envoyer
 comm = le communicateur utilisé pour le message.
 Returns: l'information de succès.
+/
int ssend (A) (int proc, int tag, A value, MPI_Comm comm) {
    return MPI_Ssend (&value, value.sizeof, MPI_BYTE, proc, tag, comm);
}

/++
 Envoi d'une chaine de char par MPI_Send
 Params:
 proc = l'identifiant du process cible
 tag = le tag du message
 value = la valeur à envoyer
 comm = le communicateur utilisé pour le message.
 Returns: l'information de succès.
+/
int send (int proc, int tag, string value, MPI_Comm comm) {
    import std.string, std.conv;
    return MPI_Send (to!(char[])(value).ptr, to!int(value.length), MPI_CHAR, proc, tag, comm);
}

/++
 Envoi d'une chaine de char par MPI_Ssend
 Params:
 proc = l'identifiant du process cible
 tag = le tag du message
 value = la valeur à envoyer
 comm = le communicateur utilisé pour le message.
 Returns: l'information de succès.
+/
int ssend (int proc, int tag, string value, MPI_Comm comm) {
    return MPI_Ssend (to!(char[])(value).ptr, to!int(value.length), MPI_CHAR, proc, tag, comm);
}

/++
 Réception d'une valeur par MPI_Recv
 Params:
 proc = l'identifiant du process source
 tag = le tag du message
 value = la valeur à récevoir (par ref)
 status = le status du message (par ref)
 comm = le communicateur utilisé pour le message.
 Returns: l'information de succès.
+/
int recv (A) (int proc, int tag, ref A value, ref MPI_Status status, MPI_Comm comm) {
    return MPI_Recv (&value, A.sizeof, MPI_BYTE, proc, tag, comm, &status);
}

/++
 Réception d'une chaine de char par MPI_Recv
 Params:
 proc = l'identifiant du process source
 tag = le tag du message
 value = la valeur à récevoir (par ref)
 status = le status du message (par ref)
 comm = le communicateur utilisé pour le message.
 Returns: l'information de succès.
+/
int recv (int proc, int tag, ref string value, ref MPI_Status status, MPI_Comm comm) {
    int size;
    MPI_Probe (proc, tag, comm, &status);
    MPI_Get_count (&status, MPI_CHAR, &size);
    char [] buf = new char [size];
    int i = MPI_Recv (buf.ptr, size, MPI_CHAR, proc, tag, comm, &status);
    value = to!string (buf);
    return i;
}

/++
 Réception d'une valeur de char par MPI_Recv, sans connaître la source
 Params:
 tag = le tag du message
 value = la valeur à récevoir (par ref)
 status = le status du message (par ref)
 comm = le communicateur utilisé pour le message.
 Returns: l'information de succès.
+/
int recv (A) (int tag, ref A value, ref MPI_Status status, MPI_Comm comm) {
    return MPI_Recv (&value, A.sizeof, MPI_BYTE, MPI_ANY_SOURCE, tag, comm, &status);
}

/++
 Réception d'une chaine de char par MPI_Recv, sans connaître la source
 Params:
 tag = le tag du message
 value = la valeur à récevoir (par ref)
 status = le status du message (par ref)
 comm = le communicateur utilisé pour le message.
 Returns: l'information de succès.
+/
int recv (int tag, ref string value, ref MPI_Status status, MPI_Comm comm) {
    int size;
    MPI_Probe (MPI_ANY_SOURCE, tag, comm, &status);
    MPI_Get_count (&status, MPI_CHAR, &size);
    char [] buf = new char [size];
    int i = MPI_Recv (buf.ptr, size, MPI_CHAR, MPI_ANY_SOURCE, tag, comm, &status);
    value = to!string (buf);
    return i;
}

/++
 Envoi et récéption d'un message par MPI_Sendrecv.
 Params:
 to = le process cible
 from = le process source
 tag = l'identifiant du message
 to_send = la valeur à envoyer
 to_recv = la valeur à recevoir (par ref)
 status = le status à mettre à jour (par ref)
 comm = le communicateur utiliser pour le message
 Returns: l'information de succès.
+/
int sendRecv (A) (int to, int from, int tag, A to_send, ref A to_recv, ref MPI_Status status, MPI_Comm comm) {
    return MPI_Sendrecv (&to_send, A.sizeof, MPI_BYTE, to, tag,
			 &to_recv, A.sizeof, MPI_BYTE, from, tag,
			 comm, &status);
}

/++
 Envoi et récéption de chaine de char par MPI_Sendrecv.
 Params:
 to_ = le process cible
 from = le process source
 tag = l'identifiant du message
 to_send = la valeur à envoyer
 to_recv = la valeur à recevoir (par ref)
 recvLength = la taille de la chaine de retour
 status = le status à mettre à jour (par ref)
 comm = le communicateur utiliser pour le message
 Returns: l'information de succès.
+/
int sendRecv (int to_, int from, int tag, string to_send, ref string to_recv, ulong recvLength, ref MPI_Status status, MPI_Comm comm) {
    auto recv = new char [recvLength];
    int i = MPI_Sendrecv (to!(char[])(to_send).ptr, cast(int) (to_send.length), MPI_CHAR, to_, tag,
			  recv.ptr, cast (int) (recvLength), MPI_CHAR, from, tag,
			  comm, &status);
    to_recv = to!string (recv);
    return i;
}


/++
 Envoi et récéption d'un message par MPI_Sendrecv_replace.
 Params:
 to = le process cible
 from = le process source
 tag = l'identifiant du message
 to_send = la valeur à envoyer et à recevoir (par ref)
 status = le status à mettre à jour (par ref)
 comm = le communicateur utiliser pour le message
 Returns: l'information de succès.
+/
int sendRecvReplace (A) (int to, int from, int tag, ref A to_send, ref MPI_Status status, MPI_Comm comm) {
    return MPI_Sendrecv_replace (&to_send, A.sizeof, MPI_BYTE, to, tag, from, tag, comm, &status);
}

/++
 Envoi et récéption de chaine de char par MPI_Sendrecv_replace.
 Params:
 to_ = le process cible
 from = le process source
 tag = l'identifiant du message
 to_send = la valeur à envoyer et à recevoir (par ref)
 status = le status à mettre à jour (par ref)
 comm = le communicateur utiliser pour le message
 Returns: l'information de succès.
 Bugs: La chaîne envoyer doit faire la même taille que celle reçu.
+/
int sendRecvReplace (int to_, int from, int tag, ref string to_send, ref MPI_Status status, MPI_Comm comm) {
    return MPI_Sendrecv_replace (to!(char [])(to_send).ptr, to!int (to_send.length), MPI_CHAR, to_, tag, from, tag, comm, &status);
}

/++
 Envoi de tableau dynamique par MPI_Send.
 Params:
 proc = l'identifiant du process cible
 tag = l'identifiant du message
 value = le tableau à envoyer
 comm = le communicateur à utiliser
 Returns: l'information de succès.
+/
int send (T : U[], U) (int proc, int tag, T value, MPI_Comm comm)
    if (!isStaticArray!T)
{
    
    return MPI_Send (value.ptr, to!int(value.length * U.sizeof), MPI_BYTE, proc, tag, comm);
}

/++
 Envoi de tableau statique par MPI_Send.
 Params:
 proc = l'identifiant du process cible
 tag = l'identifiant du message
 value = le tableau à envoyer
 comm = le communicateur à utiliser
 Returns: l'information de succès.
+/
int send (T : U [N], U, int N) (int proc, int tag, U [N] value, MPI_Comm comm)
    if (isStaticArray!T)
{
    return MPI_Send (value.ptr, to!int(value.length * U.sizeof), MPI_BYTE, proc, tag, comm);
}

/++
 Envoi de tableau par pointeur avec MPI_Send.
 Params:
 proc = l'identifiant du process cible
 tag = l'identifiant du message
 value = le tableau à envoyer
 size = la taille des données à envoyer
 comm = le communicateur à utiliser
 Returns: l'information de succès.
+/
int send (T : U*, U) (int proc, int tag, T value, ulong size, MPI_Comm comm) {
    return MPI_Send (value, to!int (size * U.sizeof), MPI_BYTE, proc, tag, comm);
}

/++
 Envoi de tableau dynamique par MPI_Ssend.
 Params:
 proc = l'identifiant du process cible
 tag = l'identifiant du message
 value = le tableau à envoyer
 comm = le communicateur à utiliser
 Returns: l'information de succès.
+/
int ssend (T : U[], U) (int proc, int tag, T value, MPI_Comm comm) {
    return MPI_Ssend (value.ptr, to!int(value.length * U.sizeof), MPI_BYTE, proc, tag, comm);
}

/++
 Envoi de tableau par pointeur avec MPI_Ssend.
 Params:
 proc = l'identifiant du process cible
 tag = l'identifiant du message
 value = le tableau à envoyer
 size = la taille des données à envoyer
 comm = le communicateur à utiliser
 Returns: l'information de succès.
+/
int ssend (T : U*, U) (int proc, int tag, T value, ulong size, MPI_Comm comm) {
    return MPI_Ssend (value, to!int (size * U.sizeof), MPI_BYTE, proc, tag, comm);
}


/++
 Réception d'un tableau dynamique par MPI_Recv
 Params:
 proc = le process source
 tag = l'identifiant du message
 value = le tableau (il va être alloué dans la fonction)
 status = le status à mettre à jour (par ref)
 comm = le communicateur à utiliser
 Returns: l'information de succès.
+/
int recv (T : U[], U) (int proc, int tag, ref T value, ref MPI_Status status, MPI_Comm comm)
    if (!isStaticArray!T)
{
    
    int size;
    MPI_Probe (proc, tag, comm, &status);
    MPI_Get_count (&status, MPI_BYTE, &size);
    value = new U [size / U.sizeof];
    return MPI_Recv (value.ptr, size, MPI_BYTE, proc, tag, comm, &status);
}

/++
 Réception d'un tableau statique par MPI_Recv (plus rapide que dynamique)
 Params:
 proc = le process source
 tag = l'identifiant du message
 value = le tableau.
 status = le status à mettre à jour (par ref)
 comm = le communicateur à utiliser
 Returns: l'information de succès.
+/
int recv (T : U [N], U, int N) (int proc, int tag, ref T value, ref MPI_Status status, MPI_Comm comm)
    if (isStaticArray!T)
{
    //value = new U [size / U.sizeof];
    return MPI_Recv (value.ptr, N * U.sizeof, MPI_BYTE, proc, tag, comm, &status);
}


/++
 Réception d'un tableau par pointeur par MPI_Recv
 Params:
 proc = le process source
 tag = l'identifiant du message
 value = le tableau, (il va être alloué).
 len = la taille reçu (par ref)
 status = le status à mettre à jour (par ref)
 comm = le communicateur à utiliser
 Returns: l'information de succès.
+/
int recv (T : U*, U) (int proc, int tag, ref T value, ref ulong len, ref MPI_Status status, MPI_Comm comm) {
    int size;
    MPI_Probe (proc, tag, comm, &status);
    MPI_Get_count (&status, MPI_BYTE, &size);
    auto val = new U [size / U.sizeof];
    auto i = MPI_Recv (val.ptr, size, MPI_BYTE, proc, tag, comm, &status);
    len = size / U.sizeof;    
    value = val.ptr;
    return i;
}


/++
 Réception d'un tableau dynamique par MPI_Recv
 Params:
 tag = l'identifiant du message
 value = le tableau (il va être alloué dans la fonction)
 status = le status à mettre à jour (par ref)
 comm = le communicateur à utiliser
 Returns: l'information de succès.
+/
int recv (T : U[], U) (int tag, ref T value, ref MPI_Status status, MPI_Comm comm) {
    int size;
    MPI_Probe (MPI_ANY_SOURCE, tag, comm, &status);
    MPI_Get_count (&status, MPI_BYTE, &size);
    value = new U [size / U.sizeof];
    return MPI_Recv (value.ptr, size, MPI_BYTE, MPI_ANY_SOURCE, tag, comm, &status);
}


/++
 Envoi et réception d'un tableau dynamique par MPI_Recv
 Params:
 to = le process cible
 from = le process source
 tag = l'identifiant du message
 to_send = le tableau à envoyer
 to_recv = le tableau à recevoir (va être alloué)
 recvLength = la taille du message reçu.
 status = le status à mettre à jour (par ref)
 comm = le communicateur à utiliser
 Returns: l'information de succès.
+/
int sendRecv (T : U[], U) (int to, int from, int tag, T to_send, ref T to_recv, ulong recvLength, ref MPI_Status status, MPI_Comm comm) {
    to_recv = new U [recvLength];
    return MPI_Sendrecv (to_send.ptr, to!int(to_send.length * U.sizeof), MPI_BYTE, to, tag,
			 to_recv.ptr, to!int(recvLength * U.sizeof), MPI_BYTE, from, tag,
			 comm, &status);
}

/++
 Envoi et réception d'une chaine par MPI_Recv
 Params:
 to_ = le process cible
 from = le process source
 tag = l'identifiant du message
 to_send = le tableau à envoyer
 to_recv = le tableau à recevoir (va être alloué)
 status = le status à mettre à jour (par ref)
 comm = le communicateur à utiliser
 Returns: l'information de succès.
 Bugs: le message reçu doit faire la même taille que celui envoyé
+/
int sendRecv (T : string) (int to_, int from, int tag, T to_send, ref T to_recv, ref MPI_Status status, MPI_Comm comm) {
    to_send = to!string (new char [to_send.length]);
    return MPI_Sendrecv (to!(char[])(to_send).ptr, to!int(to_send.length * char.sizeof), MPI_BYTE, to_, tag,
			 to!(char[]) (to_recv).ptr, to!int(to_send.length * char.sizeof), MPI_BYTE, from, tag,
			 comm, &status);
}


/++
 Envoi et réception d'un tableau dynamique par MPI_Recv
 Params:
 to_ = le process cible
 from = le process source
 tag = l'identifiant du message
 to_send = le tableau à envoyer
 to_recv = le tableau à recevoir (va être alloué)
 status = le status à mettre à jour (par ref)
 comm = le communicateur à utiliser
 Returns: l'information de succès.
 Bugs: le message reçu doit faire la même taille que celui envoyé
+/
int sendRecv (T : U[], U) (int to_, int from, int tag, T to_send, ref T to_recv, ref MPI_Status status, MPI_Comm comm) {
    to_send = new U [to_send.length];
    return MPI_Sendrecv (to!(U[])(to_send).ptr, to!int(to_send.length * U.sizeof), MPI_BYTE, to_, tag,
			 to!(U[])(to_recv).ptr, to!int(to_send.length * U.sizeof), MPI_BYTE, from, tag,
			 comm, &status);
}

/++
 Envoi et réception d'un tableau dynamique par MPI_Recv
 Params:
 to_ = le process cible
 from = le process source
 tag = l'identifiant du message
 to_send = le tableau à envoyer et recevoir (par ref)
 status = le status à mettre à jour (par ref)
 comm = le communicateur à utiliser
 Returns: l'information de succès.
+/
int sendRecvReplace (T : U[], U) (int to_, int from, int tag, ref T to_send, ref MPI_Status status, MPI_Comm comm) {
    return MPI_Sendrecv_replace (to_send.ptr, to!int(to_send.length * U.sizeof), MPI_BYTE,
				 to_, tag,
				 from, tag,
				 comm, &status);
}



