module assign.Lambda;
import std.traits;

template Lambda (alias Fun, string fun) {
    
    string toString () {
	return fun;
    }
    
    auto call (T ...) (T values) {
	static if (is (ReturnType!(Fun) == void)) {
	    Fun (values);
	} else {
	    return Fun (values);
	}
    }    

}
