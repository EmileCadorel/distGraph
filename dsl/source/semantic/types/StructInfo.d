module semantic.types.StructInfo;
import semantic.InfoType;
import semantic.types._;
import ast._;

class StructInfo : InfoType {

    private Struct _str;

    this (Struct str) {
	this._str = str;
    }

    override InfoType dotOp (string name) {
	foreach (it ; this._str.params) {
	    if (it.ident.str == name) {
		return it.type.info.clone ();
	    }
	}
	return null;
    }
    
    override InfoType clone () {
	return new StructInfo (this._str);
    }
   
    override string toString () {
	import std.format;
	return format ("struct %s", this._str.ident.str);
    }	        
}
