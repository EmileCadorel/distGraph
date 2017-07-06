module ast.Break;
import ast.Instruction;
import syntax.Word;

class Break : Instruction {

    this (Word token) {
	super (token);
    }

    override string toString () {
	return "break;";
    }

}
