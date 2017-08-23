module dsl.semantic.types.StructCstInfo;
import visit = dsl.semantic.Visitor;
import dsl._;

class StructCstInfo : InfoType {

    private Struct _str;

    this (Struct str) {
	this._str = str;
    }

    override InfoType parOp (ParamList params) {
	foreach (it ; 0 .. params.params.length) {
	    auto type = visit.getType (this._str.params [it].type);
	    auto info = params.params [it].sym.type.affOp (Tokens.EQUAL, type);
	    if (info is null) return null;
	}
	return new StructInfo (this._str);
    }
    
    override InfoType clone () {
	return new StructCstInfo (this._str);
    }

    override string toString () {
	assert (false, "Non");
    }

    Struct str () {
	return this._str;
    }
    
}
