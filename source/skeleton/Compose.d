module skeleton.Compose;

public import skeleton.Degree;
public import skeleton.Generate;
public import skeleton.Map;
public import skeleton.Reduce;
public import skeleton.SubGraph;
public import skeleton.Zip;
public import skeleton.MapVertices;
public import skeleton.MapReduceVertices;
public import skeleton.MapEdges;
public import skeleton.FilterVertices;
public import skeleton.FilterEdges;
public import skeleton.MapReduceTriplets;
public import skeleton.JoinVertices;
public import skeleton.Pregel;
public import skeleton.PowerGraph;

import std.typecons;
import std.traits;
import utils.Singleton;

alias Ids (T) = Tuple!(ulong, "id", T, "value");

void isSkeletable (alias fun) () {
    static assert ((is (typeof(&fun) U : U*) && (is (U == function)) ||
		    is (typeof (&fun) U == delegate)) ||
		   (is (fun T2) && is(T2 == function)) ||
		   isFunctionPointer!fun ||
		   isDelegate!fun);
}
