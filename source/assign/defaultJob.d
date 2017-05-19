/++
 Ce module comporte un ensemble de fonction utilisé par le serveur pour obtenir des informations sur les autres machines.
+/
module assign.defaultJob;
import assign.launching;
import assign.Job;
import assign.cpu;
import std.stdio;

alias MemoryJob = Job!(memJob, memRespJob);

void memJob (uint addr, uint id) {
    Server.jobResult (addr, new MemoryJob (), id, SystemInfo.memoryInfo.memAvailable);   
}

void memRespJob (uint addr, uint id, ulong length) {
    Server.sendMsg (length);
}



