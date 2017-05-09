import std.stdio;
import assign.cpu;

void main() {
    writeln (CpuInfo.hyperThreading);
    writeln (CpuInfo.nbCoresPerCpu);
    writeln (CpuInfo.nbThreadsPerCpu);
    writeln (CpuInfo.nbCacheLevels);
    writeln (CpuInfo.cacheInfo);
    writeln (CpuInfo.toString);
    writeln (CpuInfo.memoryInfo);
}
