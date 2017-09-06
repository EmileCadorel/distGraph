module dsl.semantic.types.VoidInfo;
import dsl.semantic.InfoType;
import dsl.syntax.Tokens;


class VoidInfo : InfoType {
    
    override InfoType clone () {
	return new VoidInfo ();
    }

    override string toString () {
	return "void";
    }
    
}
