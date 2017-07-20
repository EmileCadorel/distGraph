module ast.Var;
import ast.Expression;
import syntax.Word;

class Var : Expression {


    this (Word ident) {
	super (ident);
    }        

    override string toString () {
	return this._token.toString ();
    }

}
