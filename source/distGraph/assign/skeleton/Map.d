module distGraph.assign.skeleton.Map;
import distGraph.assign.launching;
import std.traits;
import distGraph.assign.Job;
import core.thread;
import distGraph.assign.data.Array;
import distGraph.assign.cpu;
import std.stdio, std.conv, std.typecons;
import dsl._;
import CL = openclD._;

private auto kernSrc = q{
    __skel map (T, alias FUN) (T [] a, ulong begin, ulong size) {
	auto i = get_global_id (0);
	if (i < size)
	    a [i] = FUN (i + begin, a [i]);
    }    
};

string nameOf (T) () {
    import std.string;
    auto name = typeid (T).toString;
    auto index = name.lastIndexOf (".");
    if (index != -1) return name [index + 1 .. $];
    return name;
}

template Map (alias FUN) {
    auto Map (T) (DistArray!T data) {
	return MapImpl!(T, FUN) (data);
    }
}

template MapImpl (T, alias Fun) {

    
    alias thisJob = Job!(mapJob, endJob);
    
    static CL.Kernel [string] __compiled__;

    static class MapThread : Thread {

	private T [] _datas;
	private ulong _begin;
	
	this (ulong begin, T [] datas) {
	    super (&this.run);
	    this._begin = begin;
	    this._datas = datas;
	}

	void run () {
	    if (this._datas.length != 0) {
		foreach (it ; 0 .. this._datas.length) {
		    static if (__traits (compiles, Fun.call)) 
			this._datas [it] = Fun.call (it + this._begin, this._datas [it]);
		    else
			this._datas [it] = Fun (it + this._begin, this._datas [it]);	
		}
	    }
	}
	
    }
    
    static void map (ulong begin, T [] datas) {
	auto result = 0;
	for (ulong i = 0 ; i < datas.length ; i++) {
	      static if (__traits (compiles, Fun.call)) 
		datas [i] = Fun.call (i + begin, datas [i]);
	    else
		datas [i] = Fun (i + begin, datas [i]);	
	}
    }
    
    static CL.Kernel initOpenCL (CL.Device dev) {
	import std.path, std.file;
	static if (__traits (compiles, Fun.call)) {
	    auto it = (Fun.toString ~ dev.id.to!string) in __compiled__;
	    
	    CL.Kernel toLaunch;
	    if (it is null) {
		auto src = new Visitor (kernSrc, false).visit ();
		auto structs = new Visitor (TABLE.inFileStructs).visit ();
		foreach (str ; structs.strs) TABLE.addStr (str);
		sem.validate ();
		
		auto skel = src.getSkel ("map");
		TABLE.addSkel (skel);

		auto inline = new Inline ("map");
		inline.addTemplate (new Var (nameOf!(T)));
		inline.addTemplate (new Visitor (Fun.toString, false).visitLambda ());
		sem.createFunc (skel, inline);
		toLaunch = new CL.Kernel (dev, sem.target, "map0");
		__compiled__ [Fun.toString ~ dev.id.to!string] = toLaunch;
		TABLE.clear ();		
	    } else toLaunch = *it;

	    return toLaunch;

	} else
	    return null;
    }
    
    static void localJob (ulong begin, T [] datas) {
	auto nbCpu = SystemInfo.cpusInfo().length;
	auto nbDevice = CL.CLContext.instance.devices.length;
	auto nb = nbCpu + nbDevice;
	auto res = new Thread [nbCpu - 1];

	CL.Kernel[] kerns = new CL.Kernel [nbDevice];
	CL.Vector!T[] vecs = new CL.Vector!T [nbDevice];
	
	foreach (dev ; 0 .. CL.CLContext.instance.devices.length) {
	    kerns [dev] = initOpenCL (CL.CLContext.instance.devices [dev]);
	    if (kerns [dev] is null) {
		nb = nbCpu;
		break;
	    }
	}
	foreach (it ; 1 .. nb) {
	    if (it != nb - 1) {
		auto b = datas [(datas.length / nb) * it ..
				(datas.length / nb) * (it + 1)];
		if (it < nbCpu) 
		    res [it - 1] = new MapThread (begin + (datas.length / nb) * it, b).start ();
		else {
		    vecs [it - nbCpu] = new CL.Vector!T (b);
		    auto blockSize = CL.CLContext.instance.devices [it - nbCpu].blockSize;
		    kerns [it - nbCpu] ((b.length +  blockSize - 1) / blockSize,
					blockSize,
					vecs [it - nbCpu],
					begin + (datas.length / nb) * it,					      
					b.length);
		}
	    } else {
		auto b = datas [(datas.length / nb) * it ..
							    $];
		if (it < nbCpu)
		    res [it - 1] = new MapThread (begin + (datas.length / nb) * it, b).start ();
		else {
		    vecs [it - nbCpu] = new CL.Vector!T (b);
		    auto blockSize = CL.CLContext.instance.devices [it - nbCpu].blockSize;
		    kerns [it - nbCpu] ((b.length +  blockSize - 1) / blockSize,
					blockSize,
					vecs [it - nbCpu],
					begin + (datas.length / nb) * it,					      
					b.length);
		}
	    }
	}

	map (begin, datas [0 .. datas.length / nb]);
	
	foreach (it ; res) {
	    it.join ();
	}

	if (nb != nbCpu)
	    foreach (it ; 0 .. kerns.length) {
		kerns [it].join ();
		vecs [it].copyToLocal ();
	    }	
    }    

    static void mapJob (uint addr, uint id) {
	auto array = DataTable.get!(DistArray!T) (id);
	localJob (array.begin, array.local);	
	Server.jobResult!(thisJob) (addr, id);
    }

    static void endJob (uint addr, uint id) {
	Server.sendMsg (id);
    }
    
    auto MapImpl (DistArray!T array) {
	alias thisJob = Job!(mapJob, endJob);
	foreach (id ; Server.connected) {
	    Server.jobRequest!(thisJob) (id, array.id);	    
	}

	localJob (array.begin, array.local);
	
	foreach (id ; Server.connected) {
	    Server.waitMsg!(uint);	    
	}
	
	return array;	
    }

}
