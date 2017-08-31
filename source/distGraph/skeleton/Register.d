module distGraph.skeleton.Register;
import distGraph.utils.FunctionTable;
import distGraph.utils.Singleton;

/++
 Singleton utiliser pour enregister de manière statique les pointeurs sur fonction.
 De cette manière il est possible d'associer un nom de fonction sous forme de chaine, à son pointeur.
 Bugs: 
 Il est nécéssaire de connaître le type pour pouvoir caster la fonction avant son appel.
+/
class Register {

    private void* [string] _funcTable;
    
    /++
     Ajoute les fonctions de tout un module.
     Params:
     mod = le nom du module.
     +/
    void add (string mod) () {
	auto func_table = makeFunctionTable!mod;
	foreach (it ; func_table) {
	    this._funcTable [it.name] = cast (void*) (it.ptr);
	}
    }   

    /++
     Ajoute une fonction au données connu
     Params:
     name = le nom de la fonction
     func = le pointeur sur fonction
     +/
    void add (T) (string name, T func) {
	this._funcTable [name] = cast (void*) func;
    }

    /++
     Récupère un pointeur sur fonction
     Params:
     name = le nom de la fonction
     +/
    void* get (string name) {
	auto it = name in this._funcTable;
	if (it !is null) return *it;
	return null;
    }
    
    mixin Singleton;
}

alias Register.instance register;

unittest {
    // On s'enregistre soit même pour voir
    register.add!("skeleton.Register");
}
