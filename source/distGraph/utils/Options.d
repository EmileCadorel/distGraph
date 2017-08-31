module distGraph.utils.Options;
import distGraph.utils.Singleton;
import std.traits;
import std.typecons, std.algorithm, std.string;

alias Option = Tuple!(string, "id", string, "act", string, "longAct", int, "type");

enum PARAM = 1;
enum INFO = 0;

/++
 Juste pour éviter d'écrire instance à chaque fois.
+/
alias Options = OptionsS.instance;

/++
 Classe qui parse et récupère les options passé au lancement du programme.
+/
class OptionsS {

    private string _process;
    private string [string] _unknown;
    private string [Option] _options;
    private string [] _simple;

    /++
     On initialise les options.
     Params:
     args = les arguments passé au programme.
     +/
    void init (string [] args) {
	ulong it;
	this._process = args [0];
	for (it = 1; it < args.length - 1; it ++) {
	    if (args [it].length > 0 && args [it][0] == '-') {
		it = parseArgument (it, args);
	    } else this._simple ~= [args [it]];	        
	}
	if (it < args.length) {
	    if (args [$ - 1].length > 0 && args [$ - 1] [0] == '-')
		parseArgument (args.length - 1, args ~ [""]);
	    else
		this._simple ~= [args [$ - 1]];
	}
    }

    /++
     Returns: le nom du programme lancé
     +/
    string process () {
	return this._process;
    }

    /++
     Params:
     name = le nom d'une option, ou une chaine qui ne fait pas partie des options standart
     Returns: la valeur associé à l'option (peut être null)
     +/
    string opIndex (string name) {
	auto it = name in this._unknown;
	if (it !is null) return *it;
	return null;    
    }

    void opIndexAssign (string val, string name) {
	this._unknown [name] = val;
    }
    
    int opApply (scope int delegate (ref string key, ref string value) dg) {
	int result = 0;
	foreach (key, value ; this._unknown) {
	    result = dg (key, value);
	    if (result) break;
	}
	return result;
    }
    
    
    /++
     Params:
     name = le nom d'une option
     Returns: l'option à été activé au lancement du programme.
     +/
    bool active (string name) {
	if (auto it = name in this._unknown)
	    return true;
	return false;	
    }

    
    /++
     Returns: la liste des options sans valeur.
     +/
    string [] simple () {
	return this._simple;
    }

    
    private ulong parseArgument (ulong it, string [] args) {
	if (args [it].length >= 2 && args [it] [1] != '-') {
	    this._unknown [args [it]] = args [it + 1];
	    return it + 1;
	} else {
	    auto index = indexOf (args [it], "=");	    
	    if (index != -1) {
		this._unknown [args [it][0 .. index]] = args [it][index .. $];
		return it;
	    } else {
		this._unknown [args [it]] = args [it + 1];
		return it + 1;
	    }	    
	}
    }
            
    mixin Singleton;
}


