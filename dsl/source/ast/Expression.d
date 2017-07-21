module ast.Expression;
import ast.Instruction;
import syntax.Word;
import semantic.Symbol;
import semantic.InfoType;

class Expression : Instruction {

    private Symbol _sym;
    
    this (Word token) {
	super (token);
    }    

    ref Symbol sym () {
	return this._sym;
    }

    void type (InfoType type) {
	this._sym.type = type;
    }
    
    ref auto type () {
	return this._sym.type;
    }
    
}
