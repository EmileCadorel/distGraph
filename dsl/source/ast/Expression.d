module ast.Expression;
import ast.Instruction;
import syntax.Word;

class Expression : Instruction {

    this (Word token) {
	super (token);
    }    
    
}
