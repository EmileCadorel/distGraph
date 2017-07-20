module semantic.types.FloatInfo;
import semantic.InfoType;
import semantic.types._;
import syntax.Tokens;

enum FloatSize {
    SIMPLE = 1,
    DOUBLE = 2
}

FloatSize maxSize (FloatSize a, FloatSize b) {
    return a < b ? b : a;
}

class FloatInfo : InfoType {

    private FloatSize _size;
    
    this (FloatSize size) {
	this._size = size;
    }
    
    override InfoType binaryOp (string op, InfoType other) {
	switch (op) {
	case Tokens.DIV : return opNorm(other);
	case Tokens.STAR : return opNorm (other);
	case Tokens.PLUS : return opNorm (other);
	case Tokens.MINUS : return opNorm (other);

	case Tokens.DEQUAL : return opTest (other);
	case Tokens.NOT_EQUAL : return opTest (other);
	case Tokens.SUP_EQUAL : return opTest (other);
	case Tokens.INF_EQUAL : return opTest (other);
	case Tokens.INF : return opTest (other);
	case Tokens.SUP : return opTest (other);
	default : return null;
	}
    }

    override InfoType affOp (string op, InfoType other) {
	switch (op) {
	case Tokens.DIV_AFF : return opAff (other);
	case Tokens.STAR_EQUAL : return opAff (other);
	case Tokens.PLUS_AFF : return opAff (other);
	case Tokens.MINUS_AFF : return opAff (other);
	case Tokens.EQUAL : return opAff (other);
	default : return null;
	}
    }

    override InfoType unaryOp (string op) {
	switch (op) {
	case Tokens.DPLUS : return new FloatInfo (this._size);
	case Tokens.DMINUS : return new FloatInfo (this._size);
	default : return null;	    
	}
    }
    
    override InfoType affOp () {
	return new FloatInfo (this._size);
    }
    
    private InfoType opNorm (InfoType other) {
	if (cast (IntInfo) other) {
	    return new FloatInfo (this._size);
	} else if (auto ot = cast (FloatInfo) other) {
	    return new FloatInfo (maxSize (this._size, ot._size));
	}
	return null;
    }

    private InfoType opAff (InfoType other) {
	if (cast (IntInfo) other) {
	    return new FloatInfo (this._size);
	} else if (cast (FloatInfo) other) {
	    return new FloatInfo (this._size);
	}
	return null;
    }
    
    private InfoType opTest (InfoType other) {
	if (cast (IntInfo) other) {
	    return new BoolInfo ();
	} else if (cast (FloatInfo) other) {
	    return new BoolInfo ();
	}
	return null;
    }

    override FloatInfo clone () {
	return new FloatInfo (this._size);
    }
    
    FloatSize size () {
	return this._size;
    }
    
    override string toString () {
	if (this._size == FloatSize.SIMPLE)
	    return "float";
	else return "double";
    }
    
}
