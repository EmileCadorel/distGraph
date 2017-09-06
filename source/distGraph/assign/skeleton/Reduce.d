module distGraph.assign.skeleton.Reduce;
import distGraph.assign.launching;
import std.traits;
import std.stdio;
import distGraph.assign.Job;
import std.concurrency;
import distGraph.assign.cpu;
import distGraph.assign.data.Array;
import core.thread;
import CL = openclD._;

private auto kernSrc = q{
    __skel reduce (T, alias FUN) (T[] a, T[] b, ulong count, __loc T[] partialSum) {
	auto t = get_local_id (0), start = 2 * get_group_id (0) * get_local_size (0);
	if (start + t < count)
	    partialSum [t] = a [start + t];
	else partialSum [t] = 0;

	if (start + get_local_size (0) < count)
	    partialSum [get_local_size (0) + t] = a [start + get_local_size (0) + t];
	else partialSum [get_local_size (0) + t] = 0;

	for (auto stride = get_local_size (0) ; stride >= 1; stride >>= 1) {
	    barrier (CLK_LOCAL_MEM_FENCE);
	    if (t < stride)
		partialSum [t] = FUN (partialSum [t], partialSum [stride + t]);
	}

	if (t == 0)
	    b [get_group_id (0)] = partialSum [0];
    }    
};



template Reduce (alias fun) {

    auto Reduce (T) (DistArray!T data) {
	return ReduceImpl!(T, fun) (data);
    }
    
}

template ReduceImpl (T, alias fun) {
    
    alias thisJob = Job!(reduceJob, answerJob);

    static CL.Kernel [string] __compiled__;
    
    static class ReduceThread : Thread {
	private T[] datas;
	private T _res;
	
	this (T[] datas) {
	    super (&this.run);
	    this.datas = datas;
	}
	
	void run () {
	    ulong anc = datas.length;
	    ulong nb = datas.length / 2;
	    auto padd = 1;
	    while (padd < anc) {
		auto it = 0;
		for (it = 0; (it + padd) < (anc) ; it += (2*padd)) {
		    datas [it] = fun (datas [it], datas [it + padd]);
		}
		
		if (it < anc && (it - (2 * padd)) >= 0) {
		    datas [it - (2 * padd)] = fun (datas [it - (2 * padd)], datas [it]);
		    anc = it;
		}
		
		padd *= 2;
	    }
	    
	    this._res = datas [0];    
	}

	T res () {
	    return this._res;
	}
    }

    static T reduceArray () (T [] datas) {
	ulong anc = datas.length;
	ulong nb = datas.length / 2;
	auto padd = 1;
	while (padd < anc) {
	    auto it = 0;
	    for (it = 0; (it + padd) < (anc) ; it += (2*padd)) {
		datas [it] = fun (datas [it], datas [it + padd]);
	    }
	
	    if (it < anc && (it - (2 * padd)) >= 0) {
		datas [it - (2 * padd)] = fun (datas [it - (2 * padd)], datas [it]);
		anc = it;
	    }
	    
	    padd *= 2;
	}
    
	return datas [0];    
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
		
		auto skel = src.getSkel ("reduce");
		TABLE.addSkel (skel);

		auto inline = new Inline ("reduce");
		inline.addTemplate (new Var (nameOf!(T)));
		inline.addTemplate (new Visitor (Fun.toString, false).visitLambda ());
		sem.createFunc (skel, inline);
		toLaunch = new CL.Kernel (dev, sem.target, "reduce0");
		__compiled__ [Fun.toString ~ dev.id.to!string] = toLaunch;
		TABLE.clear ();		
	    } else toLaunch = *it;

	    return toLaunch;

	} else return null;	
    }

    static void localJob (T [] datas) {
	auto nbCpu = SystemInfo.cpuInfo().length;
	auto nbDevice = CL.CLContext.instance.devices.length;
	auto nb = nbDevice + nbCpu;
	auto res = new Thread [nb - 1];

	CL.Kernel [] kerns = new CL.Kernel [nbDevice];
	foreach (dev ; 0 .. CL.CLContext.instance.devices.length) {
	    kerns [dev] = initOpenCL (CL.CLContext.instance.devices [dev]);
	    if (kerns [dev] is null) {
		nb = nbCpu;
		break;
	    }
	}
	
	foreach (it ; 1 .. nbCpu) {
	    if (it != nb - 1) {
		auto b = array.local [(array.localLength / nb) * (it) .. (array.localLength / nb) * (it + 1)];
		res [it - 1] = new ReduceThread (b).start ();
	    } else {
		auto b = array.local [(array.localLength / nb) * (it) .. $];
		res [it - 1] = new ReduceThread (b).start ();
	    }
	}

	foreach (it ; 0 .. array.deviceVectors.length) {
	    if (nb != nbCpu) {
		
	    }
	}
	
	T soluce = reduceArray (array.local [0 .. (array.localLength / nb)]);
	
	foreach (it ; res) {
	    it.join ();
	    soluce = fun (soluce, (cast (ReduceThread) it).res);
	}
	
    }
    
    static void reduceJob (uint addr, uint id) {
	auto array = DataTable.get!(DistArray!T) (id);
	auto nb = SystemInfo.nbThreadsPerCpu ();
	auto res = new Thread [nb - 1];
	
	foreach (it ; 1 .. nb) {
	    if (it != nb - 1) {
		auto b = array.local [(array.localLength / nb) * (it) .. (array.localLength / nb) * (it + 1)];
		res [it - 1] = new ReduceThread (b).start ();
	    } else {
		auto b = array.local [(array.localLength / nb) * (it) .. $];
		res [it - 1] = new ReduceThread (b).start ();
	    }
	}
	
	T soluce = reduceArray (array.local [0 .. (array.localLength / nb)]);
	
	foreach (it ; res) {
	    it.join ();
	    soluce = fun (soluce, (cast (ReduceThread) it).res);
	}
       	Server.jobResult!(thisJob) (addr, id, soluce);
    }

    static void answerJob (uint addr, uint jbId, T res) {
	Server.sendMsg (res);
    }
    
    T ReduceImpl (DistArray!T array) {
	foreach (id ; Server.connected) {
	    Server.jobRequest!(thisJob) (id, array.id);	    
	}
	
	auto nb = SystemInfo.nbThreadsPerCpu ();
	auto res = new Thread [nb - 1];
	
	foreach (it ; 1 .. nb) {
	    if (it != nb - 1) {
		auto b = array.local [(array.localLength / nb) * (it) .. (array.localLength / nb) * (it + 1)];
		res [it - 1] = new ReduceThread (b).start ();
	    } else {
		auto b = array.local [(array.localLength / nb) * (it) .. $];
		res [it - 1] = new ReduceThread (b).start ();
	    }
	}
	
	T soluce = reduceArray (array.local [0 .. (array.localLength / nb)]);	

	foreach (it ; res) {
	    it.join ();
	    soluce = fun ((cast (ReduceThread) it).res, soluce);
	}
	
	foreach (id ; Server.connected) {
	    auto t = Server.waitMsg!T ();
	    soluce = fun (soluce, t);
	}
	
	return soluce;
    }
  
}
