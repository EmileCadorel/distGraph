module dsl.semantic.types.StructInfo;
import dsl.semantic.InfoType;
import dsl.semantic.types._;
import dsl.ast._;
import dsl.syntax._;

class StructInfo : InfoType {

    private Struct _str;

    this (Struct str) {
	this._str = str;
    }

    override InfoType affOp (string op, InfoType other) {
	if (op == Tokens.EQUAL) {
	    auto str = cast (StructInfo) other;
	    if (str && str._str is this._str) {
		return this.clone ();
	    }
	}
	return null;
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
