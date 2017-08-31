module dsl.ast.Var;
import dsl.ast.Expression;
import dsl.syntax.Word;

class Var : Expression {

    this (string name) {
	super (Word (Location.eof, name));
    }
    
    this (Word ident) {
	super (ident);
    }        

    override string toString () {
	return this._token.toString ();
    }

}
