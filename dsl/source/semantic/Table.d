module semantic.Table;
import utils.Singleton;
import semantic._;
import std.container;
import ast._;
import syntax._;

alias TABLE = Table.instance;

class Table {

    private Scope _globalScope;

    private SList!Scope _currentFrame;

    private Array!Struct _allStructs;

    private Array!Function _allFuncs;

    private Array!Skeleton _allSkels;
    
    private this () {
	this._globalScope = new Scope ();
    }

    void enterBlock () {
	this._currentFrame.insertFront (new Scope ());
    }

    void quitBlock () {
	this._currentFrame.removeFront ();
    }

    Symbol get (string name) {
	foreach (sc ; this._currentFrame) {
	    auto value = name in sc;
	    if (value !is null) return value;	    
	}
	
	auto ret = name in this._globalScope;
	if (ret !is null) return ret;
	else {
	    import semantic.types.BuiltInInfo, std.algorithm;
	    if (BuiltInInfo.__BUILTIN__.find (name) != [])
		return new Symbol (Word.eof, new BuiltInInfo (name));
	}
	return null;	
    }

    void add (Symbol sym) {
	if (this._currentFrame.empty) {
	    this._globalScope.add (sym);
	} else {
	    this._currentFrame.front.add (sym);
	}
    }
    
    Symbol getAlike (string name) {
	foreach (sc ; this._currentFrame) {
	    auto value = sc.getAlike (name);
	    if (value) return value;
	}
	return this._globalScope.getAlike (name);
    }

    void addFunc (Function func) {
	this._allFuncs.insertBack (func);
    }

    void addStr (Struct str) {
	this._allStructs.insertBack (str);
    }

    void addSkel (Skeleton skel) {
	this._allSkels.insertBack (skel);
    }

    Array!Struct allStructs () {
	return this._allStructs;
    }

    Array!Function allFunctions () {
	return this._allFuncs;
    }

    Array!Skeleton allSkeletons () {
	return this._allSkels;
    }
    
    string outFile () {
	return "cl.dsl.c";
    }
    
    mixin Singleton!Table;
}

