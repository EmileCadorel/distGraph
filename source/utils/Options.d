module utils.Options;
import utils.Singleton;
import std.traits;
import std.typecons, std.algorithm, std.string;

alias Option = Tuple!(string, "id", string, "act", string, "longAct", int, "type");

enum PARAM = 1;
enum INFO = 0;

/++
 Liste des options standart déjà prévu
+/
enum OptionEnum {
    TYPE = Option ("type", "-t", "--type", PARAM)    
}

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
     type = une option
     Returns: la valeur associé à l'option (peut être null)
     +/
    string opIndex (OptionEnum type) {
	auto f = type in this._options;
	if (f !is null) return *f;
	return null;
    }

    /++
     Params:
     name = le nom d'une option, ou une chaine qui ne fait pas partie des options standart
     Returns: la valeur associé à l'option (peut être null)
     +/
    string opIndex (string name) {
	auto f = find!("a.id == b") ([EnumMembers!OptionEnum], name);
	if (f != []) return this.opIndex (f [0]);
	else {
	    auto it = name in this._unknown;
	    if (it !is null) return *it;
	    return null;
	}
    }
   
    /++
     Params:
     name = le nom d'une option
     Returns: l'option à été activé au lancement du programme.
     +/
    bool active (string name) {
	auto f = find!("a.id == b") ([EnumMembers!OptionEnum], name);
	if (f != []) return true;
	else {
	    if (auto it = name in this._unknown)
		return true;
	    return false;
	}
    }
    
    /++
     Returns: la liste des options sans valeur.
     +/
    string [] simple () {
	return this._simple;
    }

    
    private ulong parseArgument (ulong it, string [] args) {
	if (args [it].length >= 2 && args [it] [1] != '-') {
	    auto ot = find!("a.act == b") ([EnumMembers!OptionEnum], args [it]);
	    if (ot == []) {
		this._unknown [args [it]] = args [it + 1];
		return it + 1;
	    } else if (ot [0].type == PARAM) {
		this._options [ot [0]] = args [it + 1];
		return it + 1;
	    } else {
		this._options [ot [0]] = "";
		return it;
	    }
	} else {
	    auto index = indexOf (args [it], "=");
	    foreach (ot ; [EnumMembers!OptionEnum]) {
		if (index == -1) { // --op
		    if (ot.longAct == args [it]) {
			if (ot.type == PARAM) {
			    this._options [ot] = "";
			    return it;
			} else {
			    this._options [ot] = args [it + 1];
			    return it + 1;
			}
		    }
		} else if (index != -1) { // --op=elem
		    if (ot.longAct == args [it] [0 .. index]) {
			this._options [ot] = args [it] [index + 1 .. $];
			return it ;
		    }
		}
	    }
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


