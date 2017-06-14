import assign.skeleton.Stream;
import assign.data.Array;
import std.stdio;
import std.datetime;

void main2 () {    
    auto stream = new Stream;
    auto gen = new Stream;
    
    enum n = 1_000_000UL;
    auto begin = Clock.currTime;
    stream.pipe (
	Generate! (
	    (ulong i) => i 
	)
    );
    
    auto res = cast (DistArray!ulong) stream.run (n);
    // foreach (it ; 0 .. res.length) {
    // 	writeln (res [it]);
    // }
    
    writeln (res, " Time : ", Clock.currTime - begin);    
}

