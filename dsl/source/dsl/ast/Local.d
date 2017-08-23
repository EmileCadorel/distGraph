module dsl.ast.Local;
import dsl.ast.Expression, dsl.ast.Var;
import dsl.ast.Instruction, dsl.ast.Type;
import std.container, std.string;
import dsl.syntax.Word;

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
