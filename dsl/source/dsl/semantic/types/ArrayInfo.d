module dsl.semantic.types.ArrayInfo;
import dsl.semantic.InfoType;
import dsl.semantic.types._;

class ArrayInfo : InfoType {

    private InfoType _content;
    
    this (InfoType content) {
	this._content = content;
    }
    
    override InfoType accessOp (InfoType type) {
	if (cast (IntInfo) type) return this._content.clone ();
	return null;
    }

    override ArrayInfo clone () {
	return new ArrayInfo (this._content.clone ());
    }

    override string toString () {
	return this._content.toString () ~ " * ";
    }
    
}
