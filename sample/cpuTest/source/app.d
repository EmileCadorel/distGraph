import std.stdio;
import assign.cpu;
import std.algorithm;


void main() {
    SystemInfo.cpusInfo.each!((a) => writeln (a));

    auto a = SystemInfo.cpusInfo [0];
    
    writeln (SystemInfo.memoryInfo);
}
