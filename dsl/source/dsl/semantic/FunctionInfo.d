module dsl.semantic.FunctionInfo;
import dsl.ast.Function;
import dsl.semantic._;

class FunctionInfo : InfoType {

    private Function _astFunc;

    this (Function func) {
	this._astFunc = func;
    }
       
}
