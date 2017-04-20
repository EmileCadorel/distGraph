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
public import skeleton.Pregel;
public import skeleton.JoinVertices;

import std.typecons;

alias Ids (T) = Tuple!(ulong, "id", T, "value");

