module distGraph.skeleton.Compose;

import std.typecons;
import std.traits;
import distGraph.utils.Singleton;

alias Ids (T) = Tuple!(ulong, "id", T, "value");

/++
 La fonction peut être utilisé comme paramètre d'un squelette.
 Params:
 fun = une fonction | delegate | pointeur sur fonction.
+/
void isSkeletable (alias fun) () {
    static assert ((is (typeof(&fun) U : U*) && (is (U == function)) ||
		    is (typeof (&fun) U == delegate)) ||
		   (is (fun T2) && is(T2 == function)) ||
		   isFunctionPointer!fun ||
		   isDelegate!fun);
}
