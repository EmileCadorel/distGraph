module dsl.ast.Break;
import dsl.ast.Instruction;
import dsl.syntax.Word;

class Break : Instruction {

    this (Word token) {
	super (token);
    }

    override string toString () {
	return "break;";
    }

}
