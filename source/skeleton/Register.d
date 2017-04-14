module skeleton.Register;
import utils.FunctionTable;
import utils.Singleton;

class Register {

    private void* [string] _funcTable;
    
    void add (string mod) () {
	auto func_table = makeFunctionTable!mod;
	foreach (it ; func_table) {
	    this._funcTable [it.name] = cast (void*) (it.ptr);
	}
    }   
    
    void add (T) (string name, T func) {
	this._funcTable [name] = cast (void*) func;
    }

    void* get (string name) {
	auto it = name in this._funcTable;
	if (it !is null) return *it;
	return null;
    }
    
    mixin Singleton!Register;
}

alias Register.instance register;

unittest {
    register!("skeleton.Register");
}
