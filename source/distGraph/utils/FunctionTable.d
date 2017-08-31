module distGraph.utils.FunctionTable;
import std.typecons;
import std.typetuple;
import std.traits;

/++
 Récupère toutes les fonctions d'un module.
 Params:
 mod = le module 
+/
template getFunctions(alias mod) {
    template filterPred(string name) {
        enum filterPred = is(typeof(__traits(getMember, mod, name)) ==
			     function);
    }
    alias names = Filter!(filterPred, __traits(allMembers, mod));

    template mapPred(string name) {
        alias mapPred = TypeTuple!(__traits(getMember, mod, name))[0];
    }
    alias getFunctions = staticMap!(mapPred, names);
}

/++
 Génére un tableau qui contient tous les pointeurs sur fonctions associé leur nom.
 Params:
 modname = le nom d'un module.
+/
auto makeFunctionTable(alias modname)() {
    mixin("import "~modname~";");
    mixin("alias funcs = getFunctions!("~modname~");");
    struct TL {
	immutable string name;
	immutable (void*) ptr;
    }
    
    TL[] make(size_t n)() {
        static if (n < funcs.length - 1)
            return [TL (fullyQualifiedName!(funcs[n]), cast(immutable(void*))&(funcs[n]))] ~ make!(n+1)();
        else {
	    return [TL (fullyQualifiedName!(funcs[n]), cast(immutable(void*))&(funcs[n]))];
	}
    }
    return make!0 ()[0 .. funcs.length];
}
