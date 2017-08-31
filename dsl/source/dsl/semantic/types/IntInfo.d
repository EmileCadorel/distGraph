module dsl.semantic.types.IntInfo;
import dsl.semantic.InfoType;
import dsl.semantic.types._;
import dsl.syntax.Tokens;


enum IntSize {
    UBYTE = 1,
    USHORT = 2,
    UINT = 3,
    ULONG = 4,
    BYTE = 5,
    SHORT = 6,
    INT = 7,
    LONG = 8
}

IntSize maxSize (IntSize a, IntSize b) {
    if (a <= IntSize.ULONG && b <= IntSize.ULONG) return a < b ? b : a;
    else if (a <= IntSize.ULONG) return a;
    else if (b <= IntSize.ULONG) return b;
    else return a < b ? b : a;
}


IntSize signed (IntSize a) {
    if (a == IntSize.UBYTE) return IntSize.BYTE;
    if (a == IntSize.USHORT) return IntSize.SHORT;
    if (a == IntSize.UINT) return IntSize.INT;
    if (a == IntSize.ULONG) return IntSize.LONG;
    return a;
}

class IntInfo : InfoType {

    private IntSize _size;
    
    this (IntSize size) {
	this._size = size;
    }
    
    override InfoType binaryOp (string op, InfoType other) {
	switch (op) {
	case Tokens.DIV : return opNorm(other);
	case Tokens.STAR : return opNorm (other);
	case Tokens.PLUS : return opNorm (other);
	case Tokens.MINUS : return opNorm (other);
	case Tokens.PERCENT : return opNorm (other);
	case Tokens.RIGHTD : return opNorm (other);
	case Tokens.XOR : return opNorm (other);
	case Tokens.LEFTD : return opNorm (other);
	case Tokens.PIPE : return opNorm (other);
	case Tokens.AND : return opNorm (other);

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
	case Tokens.DPLUS : return new IntInfo (this._size);
	case Tokens.DMINUS : return new IntInfo (this._size);
	case Tokens.MINUS : return new IntInfo (signed (this._size));
	default : return null;	    
	}
    }
    
    override InfoType affOp () {
	return new IntInfo (this._size);
    }
    
    private InfoType opNorm (InfoType other) {
	if (auto ot = cast (IntInfo) other) {
	    return new IntInfo (maxSize (this._size, ot._size));
	} else if (auto ot = cast (FloatInfo) other) {
	    return new FloatInfo (ot.size);
	}
	return null;
    }

    private InfoType opAff (InfoType other) {
	if (cast (IntInfo) other) {
	    return new IntInfo (this._size);
	} else if (cast (FloatInfo) other) {
	    return new IntInfo (this._size);
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

    override IntInfo clone () {
	return new IntInfo (this._size);
    }
    
    IntSize size () {
	return this._size;
    }
    
    override string toString () {
	final switch (this._size) {
	case IntSize.UBYTE : return "unsigned char";
	case IntSize.USHORT : return "unsigned short int";
	case IntSize.UINT : return "unsigned int";
	case IntSize.ULONG : return "unsigned long int";
	case IntSize.BYTE : return "char";
	case IntSize.SHORT : return "short int";
	case IntSize.INT : return "int";
	case IntSize.LONG : return "long int";
	}
    }
    
}
