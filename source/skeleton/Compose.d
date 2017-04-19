module skeleton.Compose;

public import skeleton.Degree;
public import skeleton.Generate;
public import skeleton.Map;
public import skeleton.Reduce;
public import skeleton.Reverse;
public import skeleton.SubGraph;
public import skeleton.Zip;

import std.typecons;

alias Ids (T) = Tuple!(ulong, "id", T, "value");

