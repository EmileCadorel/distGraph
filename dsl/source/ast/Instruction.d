module ast.Instruction;
import syntax.Word;

class Instruction {

    // Le nombre de block supérieur.
    protected uint _indent; 

    protected Word _token;

    this (Word token) {
	this._token = token;
    }

    ref uint indent () {
	return this._indent;
    }

    Word token () {
	return this._token;
    }
    
}
