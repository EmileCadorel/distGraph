module semantic.types.BoolInfo;
import semantic.InfoType;
import syntax.Tokens;

class BoolInfo : InfoType {

    override InfoType binaryOp (string op, InfoType other) {
	switch (op) {
	case Tokens.DAND : return opTest (other);
	case Tokens.DPIPE : return opTest (other);
	case Tokens.DEQUAL : return opTest (other);
	case Tokens.NOT_EQUAL : return opTest (other);
	default: return null;
	}
    }
    
    override InfoType affOp (string op, InfoType other) {
	if (op == Tokens.EQUAL) {
	    if (cast (BoolInfo) other) return new BoolInfo ();
	}
	return null;
    }

    override InfoType affOp () {
	return new BoolInfo ();
    }

    private InfoType opTest (InfoType other) {
	if (cast (BoolInfo) other) return new BoolInfo ();
	return null;
    }

    override InfoType clone () {
	return new BoolInfo ();
    }
    
    override string toString () {
	return "char";
    }    

}
