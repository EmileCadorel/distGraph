module distGraph.assign.skeleton.Init;
import distGraph.assign.launching;
import std.traits;
import distGraph.assign.Job;
import std.concurrency;
import distGraph.assign.data.Array;
import distGraph.assign.cpu;
import std.conv;
import std.stdio, core.thread;
import CL = openclD._;
import dsl._;

private auto kernSrc = q{
    __skel init (T, alias FUN) (T [] a, ulong begin, ulong size) {
	auto i = get_global_id (0);
	if (i < size) 
	    a [i] = FUN (begin + i);	
    }    
};


template Init (alias fun) {
    auto Init (T) (DistArray!T data) {
	return InitImpl!(T, fun) (data);
    }
}

string nameOf (T) () {
    import std.string;
    auto name = typeid (T).toString;
    auto index = name.lastIndexOf (".");
    if (index != -1) return name [index + 1 .. $];
    return name;
}

template InitImpl (T, alias fun) {

    alias thisJob = Job!(initJob, endJob);

    static CL.Kernel [string] __compiled__;
    
    static class InitThread : Thread {
	private T[] _datas;
	private ulong _begin;

	this (ulong begin, T[] datas) {
	    super (&this.run);
	    this._begin = begin;
	    this._datas = datas;
	}

	void run () {
	    if (this._datas.length != 0) {
		foreach (it ; 0 .. this._datas.length) {
		    static if (__traits (compiles, fun.call)) {
			this._datas [it] = cast (T) fun.call (this._begin + it);
		    } else {
			this._datas [it] = cast (T) fun (this._begin + it);
		    }
		}
	    }
	}
    }

    
    static void init (ulong begin, T [] datas) {
	if (datas.length != 0) {
	    foreach (it ; 0 .. datas.length) {
		static if (__traits (compiles, fun.call)) {
		    datas [it] = cast (T) fun.call (begin + it);
		} else {		    
		    datas [it] = cast (T) fun (begin + it);
		}
	    }
	}
    }


    static CL.Kernel initOpenCL (CL.Device dev) {
	import std.path, std.file;
	static if (__traits(compiles, fun.call)) {
	    auto it = (fun.toString ~ dev.id.to!string) in __compiled__;

	    CL.Kernel toLaunch;
	    if (it is null) {
		auto src = new Visitor (kernSrc, false).visit ();
		auto structs = new Visitor (TABLE.inFileStructs).visit ();
		foreach (str ; structs.strs) TABLE.addStr (str);
		sem.validate ();
				
		auto skel = src.getSkel ("init");
		TABLE.addSkel (skel);

		auto inline = new Inline ("init");
		inline.addTemplate (new Var (nameOf!(T)));
		inline.addTemplate (new Visitor (fun.toString, false).visitLambda ());
		sem.createFunc (skel, inline);
		toLaunch = new CL.Kernel (dev, sem.target, "init0");
		__compiled__ [fun.toString ~ dev.id.to!string] = toLaunch;
		TABLE.clear ();
	    } else toLaunch = *it;

	    return toLaunch;
	} else return null;		
    }

    static void localJob (DistArray!T array) {
	auto nb = SystemInfo.cpusInfo().length;
	auto nbDevice = CL.CLContext.instance.devices.length;
	auto res = new Thread [nb - 1];

	CL.Kernel[] kerns = new CL.Kernel [nbDevice];
	CL.Vector!T[] vecs = new CL.Vector!T [nbDevice];
	
	foreach (dev ; 0 .. nbDevice) {
	    kerns [dev] = initOpenCL (CL.CLContext.instance.devices [dev]);
	    if (kerns [dev] is null) {
		break;
	    }
	}
	foreach (it ; 1 .. nb) {
	    if (it != nb - 1) {
		auto b = array.local [(array.local.length / nb) * it ..
				(array.local.length / nb) * (it + 1)];
		res [it - 1] = new InitThread (array.begin + (array.local.length / nb) * it, b).start ();
	    } else {
		auto b = array.local [(array.local.length / nb) * it .. $];
		res [it - 1] = new InitThread (array.begin + (array.local.length / nb) * it, b).start ();		
	    }
	}
	
	auto len = 0;
	foreach (it ; 0 .. array.deviceLocals.length) {
	    auto b = array.deviceLocals [it];
	    if (kerns [it] !is null) {
		auto blockSize = CL.CLContext.instance.devices [it].blockSize;
		kerns [it] ((b.length +  blockSize - 1) / blockSize,
			    blockSize,
			    b,
			    array.begin + array.local.length + len,
			    b.length);       			
	    } else { // Oblige de le faire sur le CPU
		b.copyToLocal ();
	        init (array.begin + array.local.length + len, b.local);
	    }
	    len += b.length;
	}
	
	init (array.begin, array.local [0 .. array.local.length / nb]);
	
	foreach (it ; res) {
	    it.join ();
	}

	foreach (it ; 0 .. kerns.length) {
	    kerns [it].join ();
	}	
    }    
    
    static void initJob (uint addr, uint id) {
	auto array = DataTable.get!(DistArray!T) (id);
	localJob (array);
	Server.jobResult!(thisJob) (addr, id);
    }

    static void endJob (uint addr, uint id) {
	Server.sendMsg (id);
    }

    
    auto InitImpl (DistArray!T array) {
	foreach (id; Server.connected) {
	    Server.jobRequest!(thisJob) (id, array.id);	    
	}
	
	localJob (array);

	foreach (id ; Server.connected) {
	    Server.waitMsg!(uint);	
	}
	
	return array;
    }

}
