module dgraph.Edge;
import std.outbuffer;
import utils.Colors;
import std.traits;


struct Edge {
    ulong src, dst, color;
}
