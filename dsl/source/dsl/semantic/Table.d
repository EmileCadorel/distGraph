module dsl.semantic.Table;
import dsl.utils.Singleton;
import dsl.semantic._;
import std.container;
import dsl.ast._;
import dsl.syntax._;

alias TABLE = Table.instance;

class Table {

    private Scope _globalScope;

    private SList!Scope _currentFrame;

    private Array!Struct _allStructs;

    private Array!Function _allFuncs;

    private Array!Skeleton _allSkels;

    private Array!Program _allProg;
    
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
	    import dsl.semantic.types.BuiltInInfo, std.algorithm;
	    if (BuiltInInfo.__BUILTIN__.find (name) != [])
		return new Symbol (Word.eof, new BuiltInInfo (name));
	}
	return null;	
    }

    Function getFunc (string name) {
	foreach (it ; this._allFuncs) {
	    if (it.ident.str == name) return it;
	}
	return null;
    }

    Skeleton getSkel (string name) {
	foreach (it ; this._allSkels) {
	    if (it.ident.str == name) return it;
	}
	return null;
    }

    Struct getStruct (string name) {
	foreach (it ; this._allStructs) {
	    if (it.ident.str == name) return it;
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

    void addProg (Program prg) {
	this._allProg.insertBack (prg);
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

    Array!Program allPrograms () {
	return this._allProg;
    }

    string outdir () {
	import std.file, std.string;
	auto path = thisExePath ();
	return path [0 .. path.lastIndexOf ("/") + 1] ~ "cl_kernels/";
    }
    
    string outFile () {
	import std.path;
	return buildPath (outdir, "dsl.c");
    }

    string outFileStructs () {
	import std.path;
	return buildPath (outdir, "structs.h");
    }
    
    string inFileStructs () {
	import std.path;
	return buildPath (outdir, "in_structs.d");
    }

    void clear () {
	this._globalScope = new Scope ();
	this._currentFrame = make!(SList!Scope);
	this._allStructs = make!(Array!Struct);
	this._allFuncs = make!(Array!Function);
	this._allSkels = make!(Array!Skeleton);
	this._allProg = make!(Array!Program);
    }
    
    mixin Singleton!Table;
}

