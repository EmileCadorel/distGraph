module semantic.Scope;
import semantic._;
import std.container, std.string, std.algorithm;



class Scope {

    private Symbol [string] _local;

    Symbol opIndex (string name) {
	auto it = name in this._local;
	if (it !is null) return (*it);
	else return null;
    }

    Symbol opBinaryRight (string op = "in") (string name) {
	auto it = name in this._local;
	if (it !is null) return (*it);
	else return null;
    }

    void add (Symbol sym) {
	this._local [sym.name] = sym;
    }    
    
    void clear () {
	this._local = null;
    }

    Symbol getAlike (string name) {
	auto min = 3UL;
	Symbol ret = null;
	foreach (key, value ; this._local) {
	    auto diff = levenshteinDistance (key, name);
	    if (diff < min) {
		ret = value;
		min = diff;
	    }
	}
	return ret;
    }        
    
}
