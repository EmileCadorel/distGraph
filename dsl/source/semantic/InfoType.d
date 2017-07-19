module semantic.InfoType;
import syntax.Word;

class InfoType {      

    InfoType binaryOp (string, InfoType) {
	return null;
    }

    InfoType unaryOp (string) {
	return null;
    }
    
    InfoType affOp (string, InfoType) {
	return null;
    }

    InfoType accessOp (InfoType type) {
	return null;
    }
    
    InfoType affOp () {
	return null;
    }

    abstract InfoType clone ();

    override abstract string toString ();
    
}
