module assign.cpu;
import core = core.cpuid;
import utils.Singleton;

struct MemInfo {
    ulong memTotal;
    ulong memFree;
    ulong memAvailable;
    ulong buffers;
    ulong cached;
    ulong swapCached;
    ulong active;
    ulong inactive;
    ulong activeAnon;
    ulong inactiveAnon;
    ulong activeFile;
    ulong inactiveFile;
    ulong unevictable;
    ulong mLocked;
    ulong swapTotal;
    ulong swapFree;
    ulong dirty;
    ulong writeBack;
    ulong anonPages;
    ulong mapped;
    ulong shMem;
    ulong sLab;
    ulong sReclaimable;
    ulong sUnreclaim;
    ulong kernelStack;
    ulong pageTables;
    ulong nfsUnstable;
    ulong bounce;
    ulong writeBackTmp;
    ulong commitLimit;
    ulong committedAs;
    ulong vMallocTotal;
    ulong vMallocUsed;
    ulong vMallocChunk;
    ulong hardwareCorrupted;
    ulong anonHugePages;
    ulong cmaTotal;
    ulong cmaFree;
    ulong hugePagesTotal;
    ulong hugePagesFree;
    ulong hugePagesRsvd;
    ulong hugePagesSurp;
    ulong hugePageSize;
    ulong directMap4k;
    ulong directMap2M;
}

class CpuInfoS {
    
    bool hyperThreading () {
	return core.hyperThreading ();
    }
    
    uint nbThreadsPerCpu () {
	return core.threadsPerCPU ();
    }

    uint nbCoresPerCpu () {
	return core.coresPerCPU ();
    }

    uint nbCacheLevels () {
	return core.cacheLevels ();
    }

    const (core.CacheInfo)[5] cacheInfo () {
	return core.dataCaches ();
    }
        
    override string toString () {
	return core.processor ();
    }

    MemInfo memoryInfo () {
	return this.parseFile ();
    }

    private MemInfo parseFile () {
	import std.stdio, std.conv, std.string;
	auto file = File ("/proc/meminfo");
	MemInfo ret;
	while (true) {
	    auto line = file.readln ();
	    if (line is null || line.strip == "") break;
	    auto index = line.indexOf (":");
	    auto sizeIndex = line.lastIndexOf ("kB");
	    if (index == -1) assert (false, "[" ~ line ~ "]");
	    else {
		if (sizeIndex == -1) sizeIndex = line.length;
		auto size = line [index + 1 .. sizeIndex].strip.to!ulong;
		switch (line [0 .. index]) {
		case "MemTotal" : ret.memTotal = size; break;
		case "MemFree" : ret.memFree = size; break;
		case "MemAvailable" : ret.memAvailable = size; break;
		case "Buffers" : ret.buffers = size; break;
		case "Cached" : ret.cached = size; break;
		case "SwapCached" : ret.swapCached = size; break;
		case "Active" : ret.active = size; break;
		case "Inactive" : ret.inactive = size; break;
		case "Active(anon)" : ret.activeAnon = size; break;
		case "Inactive(anon)" : ret.inactiveAnon = size; break;
		case "Active(file)" : ret.activeFile = size; break;
		case "Inactive(file)" : ret.inactiveFile = size; break;
		case "Unevictable" : ret.unevictable = size; break;
		case "Mlocked" : ret.mLocked = size; break;
		case "SwapTotal" : ret.swapTotal = size; break;
		case "SwapFree" : ret.swapFree = size; break;
		case "Dirty" : ret.dirty = size; break;
		case "Writeback" : ret.writeBack = size; break;
		case "AnonPages" : ret.anonPages = size; break;
		case "Mapped" : ret.mapped = size; break;
		case "Shmem" : ret.shMem = size; break;
		case "Slab" : ret.sLab = size; break;
		case "SReclaimable" : ret.sReclaimable = size; break;
		case "SUnreclaim" : ret.sUnreclaim = size; break;
		case "KernelStack" : ret.kernelStack = size; break;
		case "PageTables" : ret.pageTables = size; break;
		case "NFS_Unstable" : ret.nfsUnstable = size; break;
		case "Bounce" : ret.bounce = size; break;
		case "WritebackTmp" : ret.writeBackTmp = size; break;
		case "CommitLimit" : ret.commitLimit = size; break;
		case "Committed_AS" : ret.committedAs = size; break;
		case "VmallocTotal" : ret.vMallocTotal = size; break;
		case "VmallocUsed" : ret.vMallocUsed = size; break;
		case "VmallocChunk" : ret.vMallocChunk = size; break;
		case "HardwareCorrupted" : ret.hardwareCorrupted = size; break;
		case "AnonHugePages" : ret.anonHugePages = size; break;
		case "CmaTotal" : ret.cmaTotal = size; break;
		case "CmaFree" : ret.cmaFree = size; break;
		case "HugePages_Total" : ret.hugePagesTotal = size; break;
		case "HugePages_Free" : ret.hugePagesFree = size; break;
		case "HugePages_Rsvd" : ret.hugePagesRsvd = size; break;
		case "HugePages_Surp" : ret.hugePagesSurp = size; break;
		case "Hugepagesize" : ret.hugePageSize = size; break;
		case "DirectMap4k" : ret.directMap4k = size; break;
		case "DirectMap2M" : ret.directMap2M = size; break;
		default: assert (false, "Not mapped " ~ line [0 .. index]);
		}
	    }
	}
	return ret;
    }
	       
    
    mixin Singleton;   
}

alias CpuInfo = CpuInfoS.instance;




