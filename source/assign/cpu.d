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
    ulong shMemHugePages;
    ulong shMemPmdMapped;
    ulong cmaTotal;
    ulong cmaFree;
    ulong hugePagesTotal;
    ulong hugePagesFree;
    ulong hugePagesRsvd;
    ulong hugePagesSurp;
    ulong hugePageSize;
    ulong directMap4k;
    ulong directMap2M;
    ulong directMap1G;
}

struct CpuInfo {
    uint id;
    string vendorId;
    uint cpuFamily;
    uint model;
    string modelName;
    uint stepping;
    string microcode;
    float mHz;
    uint cacheSize;
    uint physicalId;
    uint siblings;
    uint coreId;
    uint cpuCores;
    uint apicid;
    uint initApicid;
    bool fpu;
    bool fpuException;
    uint cpuidLevel;
    bool wp;
    string [] flags;
    string bugs;
    float bogoMips;
    uint clFlushSize;
    uint cacheAlignment;
    uint [2] addressSizes;
    string powerManagement;
}

bool support (CpuInfo cpu, string flag) {
    import std.algorithm;
    return cpu.flags.find (flag) != [];
}


class SystemInfoS {
    
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

    CpuInfo [] cpusInfo () {
	return this.parseCpuFile ();
    }
    
    MemInfo memoryInfo () {
	return this.parseMemFile ();
    }

    private CpuInfo [] parseCpuFile () {
	import std.stdio, std.conv, std.string, std.container, std.array;
	auto file = File ("/proc/cpuinfo");
	Array!CpuInfo infos;
	while (true) {
	    auto line = file.readln ();
	    if (line is null || (line.strip == "" && file.eof)) break;
	    if (line.strip == "") continue;
	    auto index = line.indexOf (":");
	    if (index == -1) assert (false, "[" ~ line ~ "]");
	    else {
		switch (line [0 .. index].strip) {
		case "processor" : infos.insertBack (CpuInfo (line [index + 1 .. $].strip.to!uint)); break;
		case "vendor_id" : infos.back ().vendorId = line [index + 1 .. $].strip; break;
		case "cpu family" : infos.back ().cpuFamily = line [index + 1 .. $].strip.to!uint; break;
		case "model" : infos.back ().model = line [index + 1 .. $].strip.to!uint; break;
		case "model name" : infos.back ().modelName = line [index + 1 .. $].strip; break;
		case "stepping" : infos.back ().stepping = line [index + 1 .. $].strip.to!uint; break;
		case "microcode" : infos.back ().microcode = line [index + 1 .. $].strip; break;
		case "cpu MHz" : infos.back ().mHz = line [index + 1 .. $].strip.to!float; break;
		case "cache size" : infos.back ().cacheSize = line [index + 1 .. $].strip [0 .. $ - 2].strip.to!uint; break;
		case "physical id" : infos.back().physicalId = line [index + 1 .. $].strip.to!uint; break;
		case "siblings" : infos.back().siblings = line [index + 1 .. $].strip.to!uint; break;
		case "core id" : infos.back().coreId = line [index + 1 .. $].strip.to!uint; break;
		case "cpu cores" : infos.back().cpuCores = line [index + 1 .. $].strip.to!uint; break;
		case "apicid" : infos.back().apicid = line [index + 1 .. $].strip.to!uint; break;
		case "initial apicid" : infos.back().initApicid = line [index + 1 .. $].strip.to!uint; break;
		case "fpu" : infos.back().fpu = line [index + 1 .. $].strip == "yes" ? true : false; break;
		case "fpu_exception" : infos.back().fpuException = line [index + 1 .. $].strip == "yes" ? true : false; break;
		case "cpuid level" : infos.back().cpuidLevel = line [index + 1 .. $].strip.to!uint; break;
		case "wp" : infos.back().wp = line [index + 1 .. $].strip == "yes" ? true : false; break;
		case "flags" : infos.back().flags = line [index + 1 .. $].strip.split; break;
		case "bugs" : infos.back ().bugs = line [index + 1 .. $]; break;
		case "bogomips" : infos.back ().bogoMips = line [index + 1 .. $].strip.to!float; break;
		case "clflush size" : infos.back().clFlushSize = line [index + 1 .. $].strip.to!uint; break;
		case "cache_alignment" : infos.back().cacheAlignment = line [index + 1 .. $].strip.to!uint; break;
		case "address sizes" : infos.back ().addressSizes = parseAddressSizes (line [index + 1 .. $]); break;
		case "power management" : infos.back.powerManagement = line [index + 1 .. $].strip; break;
		default : assert (false, "Not mapped " ~ line[0 .. index].strip);
		}
	    }
	}
	file.close ();
	return infos.array ();
    }

    private uint [2] parseAddressSizes (string line) {
	import std.string, std.conv;
	auto lines = line.split (",");
	uint [2] ret;
	ret [0] = lines [0].strip.split [0].to!uint;
	ret [1] = lines [1].strip.split [0].to!uint;
	return ret;
    }
    
    private MemInfo parseMemFile () {
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
		case "ShmemHugePages" : ret.shMemHugePages = size; break;
		case "ShmemPmdMapped" : ret.shMemPmdMapped = size; break;
		case "CmaTotal" : ret.cmaTotal = size; break;
		case "CmaFree" : ret.cmaFree = size; break;
		case "HugePages_Total" : ret.hugePagesTotal = size; break;
		case "HugePages_Free" : ret.hugePagesFree = size; break;
		case "HugePages_Rsvd" : ret.hugePagesRsvd = size; break;
		case "HugePages_Surp" : ret.hugePagesSurp = size; break;
		case "Hugepagesize" : ret.hugePageSize = size; break;
		case "DirectMap4k" : ret.directMap4k = size; break;
		case "DirectMap2M" : ret.directMap2M = size; break;
		case "DirectMap1G" : ret.directMap1G = size; break;
 		default: assert (false, "Not mapped " ~ line [0 .. index]);
		}
	    }
	}
	file.close ();
	return ret;
    }
	       
    
    mixin Singleton;   
}

alias SystemInfo = SystemInfoS.instance;




