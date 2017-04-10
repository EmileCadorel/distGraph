module dgraph.DistGraphLoader;
import utils.Singleton;
import std.stdio;
import dgraph.Graph, dgraph.Edge;
import std.string, std.conv;
import std.container, std.algorithm;
import dgraph.Partition;


class DistGraphLoaderS {

    private Graph _currentGraph;

    private string filename;

    private File _file;
    
        
    
    mixin Singleton!DistGraphLoaderS;

}

alias DistGraphLoader = DistGraphLoaderS.instance;
