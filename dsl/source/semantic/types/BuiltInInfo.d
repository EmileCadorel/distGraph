module semantic.types.BuiltInInfo;
import semantic.InfoType;
import ast._;
import semantic.types._;

class BuiltInInfo : InfoType {

    private string _name;

    static string [] __BUILTIN__;

    static this () {
	__BUILTIN__ = [
	    "get_global_id"
	];
    }
    
    this (string name) {
	this._name = name;
    }

    override InfoType parOp (ParamList params) {
	if (this._name == "get_global_id") {
	    return globalId (params);
	}
	return null;
    }

    override InfoType clone () {
	return new BuiltInInfo (this._name);
    }
    
    private InfoType globalId (ParamList params) {
	if (params.params.length == 1) {
	    if (auto ot = cast (IntInfo) params.params [0].type)
		return new IntInfo (IntSize.UINT);
	}
	return null;
    }
    
    override string toString () {
	return this._name;
    }

    
}
