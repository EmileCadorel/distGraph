module semantic.StructInfo;
import ast.Struct;
import semantic._;

class StructInfo : InfoType {

    private Struct _astStruct;

    this (Struct str) {
	this._astStruct = str;
    }
    
}
