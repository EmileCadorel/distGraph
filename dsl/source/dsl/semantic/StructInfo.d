module dsl.semantic.StructInfo;
import dsl.ast.Struct;
import dsl.semantic._;

class StructInfo : InfoType {

    private Struct _astStruct;

    this (Struct str) {
	this._astStruct = str;
    }
    
    

    
}
