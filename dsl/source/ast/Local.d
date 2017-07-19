module ast.Local;
import ast.Expression, ast.Var;
import ast.Instruction, ast.Type;
import std.container, std.string;
import syntax.Word;

class Local : Instruction {

    private Type _type;

    private Word _ident;

    this (Word token) {
	super (token);
    }

    ref Type type () {
	return this._type;
    }

    ref Word ident () {
	return this._ident;
    }    
    
}
