module semantic.FunctionInfo;
import ast.Function;
import semantic._;

class FunctionInfo : InfoType {

    private Function _astFunc;

    this (Function func) {
	this._astFunc = func;
    }
       
}
