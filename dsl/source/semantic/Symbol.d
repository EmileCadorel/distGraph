module semantic.Symbol;
import syntax.Word;
import semantic._;

class Symbol {
    private ulong _id = 0;

    private InfoType _type;

    private Word _sym;

    private bool _local;

    private static ulong __last__ = 0;
    
    this (Word sym, InfoType type) {
	this._sym = sym;
	this._type = type;
	setId ();
    }        

    Word token () {
	return this._sym;
    }
    
    string name () {
	return this._sym.str;
    }    

    void setId () {
	this._id = __last__ + 1;
	__last__ ++;
    }
    
    ref InfoType type () {
	return this._type;
    }
    
}

