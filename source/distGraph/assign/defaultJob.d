/++
 Ce module comporte un ensemble de fonction utilisé par le serveur pour obtenir des informations sur les autres machines.
+/
module distGraph.assign.defaultJob;
import distGraph.assign._;
import std.stdio;

alias MemoryJob = Job!(memJob, memRespJob);

void memJob (uint addr, uint id) {
    Server.jobResult!(MemoryJob) (addr, id, SystemInfo.memoryInfo.memAvailable);   
}

void memRespJob (uint addr, uint id, ulong length) {
    Server.sendMsg (length);
}



