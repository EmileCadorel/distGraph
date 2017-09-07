/++
 Ce module comporte un ensemble de fonction utilisé par le serveur pour obtenir des informations sur les autres machines.
+/
module distGraph.assign.defaultJob;
import distGraph.assign._;
import std.stdio;

alias MemoryJob = Job!(memJob, memRespJob);

void memJob (uint addr, uint id) {
    import CL = openclD._;
    auto mem = SystemInfo.memoryInfo.memAvailable;    
    Server.jobResult!(MemoryJob) (addr, id, mem);   
}

void memRespJob (uint addr, uint id, ulong length) {
    Server.sendMsg (length);
}



