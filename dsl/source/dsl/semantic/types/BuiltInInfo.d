module dsl.semantic.types.BuiltInInfo;
import dsl.semantic.InfoType;
import dsl.ast._;
import dsl.semantic.types._;
import std.algorithm;

class BuiltInInfo : InfoType {

    private string _name;

    static string [] __BUILTIN__;

    static this () {
	__BUILTIN__ = [
	    "get_global_id",
	    "get_local_id",
	    "get_group_id",
	    "get_local_size",
	    "barrier",
	    "CLK_LOCAL_MEM_FENCE"
	];
    }
    
    this (string name) {
	this._name = name;
    }

    override InfoType parOp (ParamList params) {
	if (["get_global_id",
	       "get_local_size",
	       "get_local_id",
	       "get_group_id"].find (this._name) != []) {
	    return ids (params);
	} else if (this._name == "barrier") {
	    return barrier (params);
	}
	return null;
    }

    override InfoType clone () {
	return new BuiltInInfo (this._name);
    }
    
    private InfoType ids (ParamList params) {
	if (params.params.length == 1) {
	    if (auto ot = cast (IntInfo) params.params [0].type)
		return new IntInfo (IntSize.UINT);
	}
	return null;
    }

    private InfoType barrier (ParamList params) {
	if (params.params.length == 1) {
	    if (auto ot = cast (BuiltInInfo) params.params [0].type) {
		if (ot._name == "CLK_LOCAL_MEM_FENCE")
		    return new VoidInfo ();
	    }
	}
	return null;
    }
    
    
    override string toString () {
	return this._name;
    }

    
}
