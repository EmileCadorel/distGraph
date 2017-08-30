module dsl.syntax.Visitor;
import dsl.syntax.Lexer, dsl.ast.PreInline;
import dsl.syntax.Word, dsl.syntax.Keys;
import dsl.syntax.Tokens, dsl.syntax.SyntaxError;
import std.stdio, std.outbuffer;
import std.container;
import std.algorithm, std.conv;
import std.math;
import dsl.ast._;

class Visitor {

    private Lexer _lex;
    private Token[] _ultimeOp;
    private Token[] _expOp;
    private Token[] _ulowOp;
    private Token[] _lowOp;
    private Token[] _highOp;
    private Token[] _befUnary;
    private Token[] _afUnary;
    private Token[] _suiteElem;
    private Token[] _forbiddenIds;
    
    this (string file) {
	this ();
	this._lex = new Lexer (file,
			       [Tokens.SPACE, Tokens.RETOUR, Tokens.RRETOUR, Tokens.TAB],
			       [[Tokens.LCOMM2, Tokens.RCOMM2],
				[Tokens.LCOMM1, Tokens.RETOUR]]);
    }
    
    this () {	
	this._ultimeOp = [Tokens.DIV_AFF, Tokens.AND_AFF, Tokens.PIPE_EQUAL,
			  Tokens.MINUS_AFF, Tokens.PLUS_AFF, Tokens.LEFTD_AFF,
			  Tokens.RIGHTD_AFF, Tokens.EQUAL, Tokens.STAR_EQUAL,
			  Tokens.PERCENT_EQUAL, Tokens.XOR_EQUAL,
			  Tokens.DXOR_EQUAL, Tokens.TILDE_EQUAL];

	this._expOp = [Tokens.DPIPE, Tokens.DAND];
	
	this._ulowOp = [Tokens.INF, Tokens.SUP, Tokens.INF_EQUAL,
			Tokens.SUP_EQUAL, Tokens.NOT_EQUAL, Tokens.NOT_INF,
			Tokens.NOT_INF_EQUAL, Tokens.NOT_SUP,
			Tokens.NOT_SUP_EQUAL, Tokens.DEQUAL];

	this._lowOp = [Tokens.PLUS, Tokens.PIPE, Tokens.LEFTD,
		       Tokens.XOR, Tokens.TILDE, Tokens.MINUS,
		       Tokens.RIGHTD];

	this._highOp = [Tokens.DIV, Tokens.AND, Tokens.STAR, Tokens.PERCENT,
			Tokens.DXOR];
	
	this._suiteElem = [Tokens.LPAR, Tokens.LCRO, Tokens.DOT, Tokens.DCOLON];
	this._afUnary = [Tokens.DPLUS, Tokens.DMINUS];	
	this._befUnary = [Tokens.MINUS, Tokens.AND, Tokens.STAR, Tokens.NOT];
	this._forbiddenIds = [Keys.IF, Keys.RETURN,
			      Keys.FOR,  Keys.WHILE, Keys.BREAK,
			      Keys.IN, Keys.ELSE, Keys.TRUE,
			      Keys.FALSE, Keys.NULL, Keys.CAST,
			      Keys.FUNCTION, Keys.AUTO
	];
    }

    ref Lexer lexer () {
	return this._lex;
    }
    
    /**
       
     */
    Program visit () {
	Array!Function funcs;
	Array!Struct str;
	Array!Inline inlines;
	Array!GlobLambda globLmbd;
	Array!Skeleton skels;
	while (true) {
	    Word word = this._lex.next ();
	    if (word.isEof) break;
	    else if (word == Keys.FUNCTION) {
		funcs.insertBack (visitFunction ());
	    } else if (word == Keys.STRUCT) {
		str.insertBack (visitStruct ());
	    } else if (word == Tokens.SHARP) {
		auto decl = visitInline ();
		if (auto inline = cast (Inline) decl)
		    inlines.insertBack (inline);
		else globLmbd.insertBack (cast (GlobLambda) (decl));
	    } else if (word == Keys.SKEL) {
		skels.insertBack (visitSkeleton ());
	    }
	}
	return new Program (this._lex.filename, funcs, str, inlines, skels, globLmbd);	
    }
   
    Function visitFunction () {
	auto begin = this._lex.rewind.next ();
	auto ident = visitIdentifiant ();
	this._lex.next (Tokens.LPAR);
	auto func = new Function (begin, ident);
	while (true) {
	    func.addParam (visitTypeVar ());	    
	    auto next = this._lex.next (Tokens.RPAR, Tokens.COMA);
	    if (next == Tokens.RPAR) break;
	}

	func.setBlock (visitBlock ());	
	func.setEnd (this._lex.next ());
	this._lex.rewind ();
	return func;
    }

    
    Struct visitStruct () {
	auto ident = visitIdentifiant ();
	auto next = this._lex.next (Tokens.LACC);
	next = this._lex.next ();
	auto str = new Struct (ident);
	if (next != Tokens.RACC) {
	    this._lex.rewind ();
	    while (true) {
		str.addVar (visitTypeVar ());
		this._lex.next (Tokens.SEMI_COLON);
		next = this._lex.next ();
		if (next == Tokens.RACC) break;
		else this._lex.rewind ();
	    }
	}
	return str;
    }

    Declaration visitGlobLambda (Word begin) {
	auto lmbd = new GlobLambda (begin);
	while (true) {
	    lmbd.vars.insertBack (visitVar);
	    auto next = this._lex.next (Tokens.COMA, Tokens.RPAR);
	    if (next == Tokens.RPAR) break;
	}
	auto next = this._lex.next (Tokens.IMPLIQUE, Tokens.LACC);
	if (next == Tokens.IMPLIQUE) {
	    lmbd.expression = visitExpression ();
	} else {
	    this._lex.rewind ();
	    lmbd.block = visitBlock ();
	}
	lmbd.end = this._lex.rewind.next ();
	return lmbd;
    }

    
    Declaration visitInline () {
	auto begin = this._lex.rewind.next ();
	auto next = this._lex.next ();
	Expression id;
	if (next == Tokens.LPAR) return visitGlobLambda (begin);
	if (next == Tokens.LCRO) {
	    id = visitExpression ();
	    next = this._lex.next (Tokens.RCRO);
	    next = this._lex.next (Tokens.DOT);	    
	} else {
	    auto dec = Word (next.locus, "0");
	    this._lex.rewind ();
	    id = new Decimal (dec);
	}
		
	auto ident = visitIdentifiant ();
	next = this._lex.next (Tokens.SEMI_COLON, Tokens.NOT);
	auto inline = new Inline (begin, id, ident, ident);
	if (next == Tokens.NOT) {
	    next = this._lex.next (Tokens.LPAR);
	    while (true) {
		next = this._lex.next ();
		this._lex.rewind ();
		if (next == Tokens.LPAR) {
		    inline.addTemplate (visitLambda ());
		} else {
		    auto type = visitIdentifiant ();
		    next = this._lex.next ();
		    if (next == Tokens.IMPLIQUE) 
			inline.addTemplate (createLambda (type, visitExpression));
		    else {
			this._lex.rewind ();
			inline.addTemplate (new Var (type));
		    }
		}
		next = this._lex.next (Tokens.COMA, Tokens.RPAR);
		if (next == Tokens.RPAR) break;
	    }
	    this._lex.next (Tokens.SEMI_COLON);
	    inline.end = next;
	}
	return inline;	
    }

    Skeleton visitSkeleton () {
	auto begin = this._lex.rewind.next ();
	auto ident = visitIdentifiant ();
	this._lex.next (Tokens.LPAR);
	auto skel = new Skeleton (begin, ident);
	while (true) {
	    auto next = this._lex.next ();
	    if (next == Keys.ALIAS) {
		skel.addFnName (visitIdentifiant ());
	    } else {
		this._lex.rewind ();
		skel.addTemplate (visitVar ());
	    }
	    next = this._lex.next (Tokens.COMA, Tokens.RPAR);
	    if (next == Tokens.RPAR) break;
	}
	this._lex.next (Tokens.LPAR);
	while (true) {
	    skel.addParam (visitTypeVar ());
	    auto next = this._lex.next (Tokens.RPAR, Tokens.COMA);
	    if (next == Tokens.RPAR) break;
	}
	skel.block = visitBlock ();
	skel.end = this._lex.next ();
	this._lex.rewind ();
	return skel;
    }
    
    
    Block visitBlock () {
	auto next = this._lex.next (Tokens.LACC);
	auto block = new Block (next);
	next = this._lex.next ();
	if (next != Tokens.RACC) {
	    this._lex.rewind ();
	    while (true) {
		block.addInst (visitInstruction ());
		next = this._lex.next ();
		if (next == Tokens.RACC) break;
		else this._lex.rewind ();
	    }
	}
	return block;
    }

    Instruction visitInstruction () {
	auto tok = this._lex.next ();
	if (tok == Keys.IF) return visitIf ();
	else if (tok == Keys.RETURN) return visitReturn ();
	else if (tok == Keys.FOR) return visitFor ();
	else if (tok == Keys.WHILE) return visitWhile ();
	else if (tok == Keys.BREAK) return visitBreak ();
	else if (tok == Keys.LOCAL) return visitLocal ();
	else if (tok == Keys.AUTO) return visitAuto ();
	else {
	    this._lex.rewind ();
	    auto retour = visitExpressionUlt ();
	    this._lex.next (Tokens.SEMI_COLON);
	    return retour;
	}
    }    

    If visitIf () {
	auto begin = this._lex.rewind.next ();
	auto test = visitExpression ();
	auto next = this._lex.next ();
	this._lex.rewind ();
	Block block;
	if (next == Tokens.LACC) block = visitBlock ();
	else {
	    block = new Block (next);
	    block.addInst (visitInstruction ());
	}
	
	auto _if = new If (begin, test, block);
	next = this._lex.next ();
	if (next == Keys.ELSE) 
	    _if.setElse (visitElse ());
	else this._lex.rewind ();
	
	return _if;
    }

    If visitElse () {
	auto begin = this._lex.rewind.next ();
	auto next = this._lex.next ();
	if (next == Keys.IF) return visitIf ();
	else {
	    this._lex.rewind ();
	    Block block;
	    if (next == Tokens.LACC) block = visitBlock ();
	    else {
		block = new Block (next);
		block.addInst (visitInstruction ());
	    }
	    return new If (begin, null, block);
	}
    }
    
    Lambda visitLambda () {
	auto begin = this._lex.next ();
	auto lmbd = new Lambda (begin);
	while (true) {
	    lmbd.addParam (visitVar ());
	    auto next = this._lex.next (Tokens.COMA, Tokens.RPAR);
	    if (next == Tokens.RPAR) break;	    
	}
	this._lex.next (Tokens.IMPLIQUE);
	lmbd.content = visitExpression ();
	return lmbd;	
    }

    Lambda createLambda (Word ident, Expression content) {
	auto lmbd = new Lambda (ident);
	lmbd.addParam (new Var (ident));
	lmbd.content = content;
	return lmbd;
    }

    Instruction visitReturn () {
	auto begin = this._lex.rewind.next ();
	auto exp = visitExpression ();
	this._lex.next (Tokens.SEMI_COLON);
	return new Return (begin, exp);
    }
    
    Instruction visitFor () {
	auto begin = this._lex.rewind.next ();
	auto _for = new For (begin);
	this._lex.next (Tokens.LPAR);	
	auto next = this._lex.next ();
	if (next != Tokens.SEMI_COLON) {
	    if (next == Keys.AUTO) _for.setBegin (visitAuto ());
	    else {
		this._lex.rewind ();
		_for.setBegin (visitExpressionUlt ());
		this._lex.next (Tokens.SEMI_COLON);
	    }
	}
	
	next = this._lex.next ();
	if (next != Tokens.SEMI_COLON) {
	    this._lex.rewind ();
	    _for.setTest (visitExpression ());
	    this._lex.next (Tokens.SEMI_COLON);
	}

	next = this._lex.next ();
	if (next != Tokens.RPAR) {
	    this._lex.rewind ();
	    while (true) {
		_for.addIter (visitExpression ());
		next = this._lex.next (Tokens.COMA, Tokens.RPAR);
		if (next == Tokens.RPAR) break;
	    }
	}
	
	next = this._lex.next ();
	this._lex.rewind ();
	if (next == Tokens.LACC) _for.setBlock (visitBlock ());
	else {
	    auto block = new Block (next);
	    block.addInst (visitInstruction ());
	    _for.setBlock (block);
	}
	return _for;
    }

    Instruction visitWhile () {
	auto begin = this._lex.rewind.next ();
	auto _while = new While (begin);
	_while.setTest (visitExpression ());
	auto next = this._lex.next ();
	this._lex.rewind ();
	if (next == Tokens.LACC) _while.setBlock (visitBlock ());
	else {
	    auto block = new Block (next);
	    block.addInst (visitInstruction ());
	    _while.setBlock (block);
	}
	return _while;
    }

    Instruction visitBreak () {
	auto begin = this._lex.rewind.next ();
	this._lex.next (Tokens.SEMI_COLON);
	return new Break (begin);
    }

    Instruction visitLocal () {
	auto begin = this._lex.rewind.next ();
	auto loc = new Local (begin);
	loc.type = visitType ();
	loc.ident = visitIdentifiant ();
	return loc;
    }
    
    Instruction visitAuto () {
	auto begin = this._lex.rewind.next ();
	auto _auto = new Auto (begin);
	while (true) {
	    auto var = visitVar ();
	    this._lex.next (Tokens.EQUAL);
	    auto expr = visitExpressionUlt ();
	    _auto.addInit (var, expr);
	    auto next = this._lex.next (Tokens.COMA, Tokens.SEMI_COLON);
	    if (next == Tokens.SEMI_COLON) break;
	}
	return _auto;
    }    

    /**
       expressionult := expression (_ultimeop expression)*
    */
    private Expression visitExpressionUlt () {
	auto left = visitExpression ();
	auto tok = _lex.next ();
	if (find(_ultimeOp, tok) != []) {
	    auto right = visitExpressionUlt ();
	    return visitExpressionUlt (new Binary (tok, left, right));
	} else _lex.rewind ();
	return left;
    }    

    private Expression visitExpressionUlt (Expression left) {
	auto tok = _lex.next ();
	if (find (_ultimeOp, tok) != []) {
	    auto right = visitExpressionUlt ();
	    return visitExpressionUlt (new Binary (tok, left, right));
	} else _lex.rewind ();
	return left;
    }
    
    private Expression visitExpression () {
	auto left = visitUlow ();
	auto tok = _lex.next ();
	if (find (_expOp, tok) != []) {
	    auto right = visitUlow ();
	    return visitExpression (new Binary (tok, left, right));
	} else _lex.rewind ();
	return left;
    }

    private Expression visitExpression (Expression left) {
	auto tok = _lex.next ();
	if (find (_expOp, tok) != []) {
	    auto right = visitUlow ();
	    return visitExpression (new Binary (tok, left, right));
	} else _lex.rewind ();
	return left;
    }
    
    private Expression visitUlow () {
	auto left = visitLow ();
	auto tok = _lex.next ();
	if (find (_ulowOp, tok) != [] || tok == Keys.IS) {
	    auto right = visitLow ();
	    return visitUlow (new Binary (tok, left, right));
	} else {
	    if (tok == Tokens.NOT) {
		auto suite = _lex.next ();
		if (suite == Keys.IS) {
		    auto right = visitLow ();
		    tok.str = Keys.NOT_IS;
		    return visitUlow (new Binary (tok, left, right));
		} else _lex.rewind ();
	    } else if (tok == Tokens.DDOT) {
		auto right = visitLow ();
		return visitUlow (new Binary (tok, left, right));
	    } 
	    _lex.rewind ();
	}
	return left;
    }

    private Expression visitNumeric (Word begin) {
	foreach (it ; 0 .. begin.str.length) {
	    if (begin.str [it] < '0' || begin.str [it] > '9') {		
		throw new SyntaxError (begin);
	    }
	}
	auto next = _lex.next ();
	if (next == Tokens.DOT) {
	    next = _lex.next ();
	    auto suite = next.str;
	    foreach (it ; next.str) {		
		if (it < '0' || it > '9') {
		    suite = "0";
		    _lex.rewind ();
		    break;
		}		    
	    }
	    return new Float (begin, suite);
	} else _lex.rewind ();
	return new Decimal (begin);
    }    

    private Expression visitFloat (Word begin) {
	auto next = _lex.next ();
	foreach (it ; next.str) {
	    if (it < '0' || it > '9')
		throw new SyntaxError (next);	    
	}
	return new Float (next);
    }
       
    private short fromHexa (string elem) {
	short total = 0;
	ulong size = elem.length - 1;
	foreach (it ; elem [0 .. $]) {
	    if (it >= 'a') {
		total += pow (16, size) * (it - 'a' + 10);
	    } else
		total += pow (16, size) * (it - '0');
	    size -= 1;
	}
	return total;
    }

    private short fromOctal (string elem) {
	short total = 0;
	ulong size = elem.length - 1;
	foreach (it ; elem [0 .. $]) {
		total += pow (8, size) * (it - '0');
	    size -= 1;
	}
	return total;
    }

    private short getFromLX (string elem) {
	foreach (it ; elem [2 .. $])
	    if ((it < 'a' || it > 'f') && (it < '0' || it > '9'))
		return -1;
	auto escape = elem [2 .. $];
	return fromHexa (escape);
    }

    private short getFromOc (string elem) {
	foreach (it ; elem [1 .. $])
	    if (it < '0' || it > '7') return -1;
	auto escape = elem [1 .. $];	
	return fromOctal (escape);
    }    
        
    private short isChar (string value) {
	auto escape = ["\\a": '\a', "\\b" : '\b', "\\f" : '\f',
		       "\\n" : '\n', "\\r" : '\r', "\\t" : '\t',
		       "\\v" : '\v', "\\" : '\\',  "\'" : '\'',
		       "\"" : '\"', "\?": '\?'];

	if (value.length == 0) return -1;
	if (value.length == 1) return cast(short) (value[0]);
	auto val = (value in escape);
	if (val !is null) return cast(short) *val;
	if (value[0] == Keys.ANTI [0]) {
	    if (value.length == 4 && value[1] == Keys.LX [0]) {
		return getFromLX (value);
	    } else if (value.length > 1 && value.length < 5) {
		return getFromOc (value);
	    }
	}
	return -1;
    }

    private Expression visitString () {
	_lex.skipEnable (Tokens.SPACE, false);       
	_lex.commentEnable (false);
	
	Word next;
	string val = ""; bool anti = false;	
	while (1) {
	    next = _lex.next ();
	    if (next.isEof ()) throw new SyntaxError (next);	    
	    else if (next == Tokens.GUILL && !anti) break;
	    else val ~= next.str;
	    if (next == Keys.ANTI) anti = true;
	    else anti = false;
	}
	_lex.skipEnable (Tokens.SPACE);
	_lex.skipEnable (Tokens.RETOUR);
	_lex.skipEnable (Tokens.RRETOUR);	
	_lex.skipEnable (Tokens.TAB);
	_lex.commentEnable ();
	
	return new String (next, val);
    }

    private Expression visitChar () {
	_lex.skipEnable (Tokens.SPACE, false);       
	_lex.commentEnable (false);
	Word next;
	string val = ""; bool anti = false;
	while (1) {
	    next = _lex.next ();
	    if (next.isEof ()) throw new SyntaxError (next);	    
	    else if (next == Tokens.APOS && !anti) break;
	    else val ~= next.str;
	    if (next == Keys.ANTI) anti = true;
	    else anti = false;
	}
	_lex.skipEnable (Tokens.SPACE);
	_lex.skipEnable (Tokens.RETOUR);
	_lex.skipEnable (Tokens.RRETOUR);	
	_lex.skipEnable (Tokens.TAB);
	_lex.commentEnable ();
	auto c = isChar (val);
	if (c <= 0) throw new SyntaxError (next);
	return new Char (next, cast (ubyte) c);
    }
    
    private Expression visitUlow (Expression left) {
	auto tok = _lex.next ();
	if (find (_ulowOp, tok) != [] || tok == Keys.IS) {
	    auto right = visitLow ();
	    return visitUlow (new Binary (tok, left, right));
	} else {
	    if (tok == Tokens.NOT) {
		auto suite = _lex.next ();
		if (suite == Keys.IS) {
		    auto right = visitLow ();
		    tok.str = Keys.NOT_IS;
		    return visitUlow (new Binary (tok, left, right));
		} else _lex.rewind ();
	    } else if (tok == Tokens.DDOT) {
		auto right = visitLow ();
		return visitHigh (new Binary (tok, left, right));
	    } 
	    _lex.rewind ();
	}
	return left;
    }

    private Expression visitLow () {
	auto left = visitHigh ();
	auto tok = _lex.next ();
	if (find (_lowOp, tok) != []) {
	    auto right = visitHigh ();
	    return visitLow (new Binary (tok, left, right));
	} else _lex.rewind ();
	return left;
    }

    private Expression visitLow (Expression left) {
	auto tok = _lex.next ();
	if (find (_lowOp, tok) != []) {
	    auto right = visitHigh ();
	    return visitLow (new Binary (tok, left, right));
	} else _lex.rewind ();
	return left;
    }

    private Expression visitHigh () {
    	auto left = visitPth ();
    	auto tok = _lex.next ();
    	if (find (_highOp, tok) != []) {
    	    auto right = visitPth ();
    	    return visitHigh (new Binary (tok, left, right));
    	} else if (tok == Keys.IN) {
	    auto right = visitPth ();
	    return visitHigh (new Binary (tok, left, right));
	} else _lex.rewind ();
    	return left;
    }

    private Expression visitHigh (Expression left) {
	auto tok = _lex.next ();
	if (find (_highOp, tok) != []) {
	    auto right = visitPth ();
	    return visitHigh (new Binary (tok, left, right));
	} else if (tok == Keys.IN) {
	    auto right = visitPth ();
	    return visitHigh (new Binary (tok, left, right));
	} else _lex.rewind ();
	return left;
    }
    
    private Expression visitPth () {
	auto tok = _lex.next ();
	if (find (_befUnary, tok) != []) {
	    return visitBeforePth (tok);
	} else {
	    if (tok != Tokens.LPAR) {
		this._lex.rewind ();
		return visitPthWPar (tok);
	    } else {
		auto exp = visitExpression ();
		this._lex.next (Tokens.RPAR);	    
		return exp;
	    }
	}
    }
    
    private Expression visitConstante () {       
	auto tok = this._lex.next ();
	if (tok.isEof ()) return null;
	if (tok.str [0] >= '0'&& tok.str [0] <= '9')
	    return visitNumeric (tok);
	else if (tok == Tokens.DOT)
	    return visitFloat (tok);
	else if (tok == Tokens.GUILL)
	    return visitString ();
	else if (tok == Tokens.APOS)
	    return visitChar ();
	else if (tok == Keys.TRUE || tok == Keys.FALSE)
	    return new Bool (tok);
	else _lex.rewind ();
	return null;
    }


    private Expression visitPthWPar (Word tok) {
	auto constante = visitConstante ();
	if (constante !is null) {
	    tok = this._lex.next ();
	    if (find (_suiteElem, tok) != []) {
		return visitSuite (tok, constante);
	    } else this._lex.rewind ();
	    return constante;
	}
	auto left = visitLeftOp ();
	tok = _lex.next ();
	if (find  (_afUnary, tok) != []) {
	    return visitAfter (tok, left);
	} else _lex.rewind ();
	return left;
    }

    private Expression visitLeftOp () {
	auto word = this._lex.next ();
	if (word == Keys.CAST) {
	    return visitCast ();
	} else if (word == Tokens.LCRO) {
	    return visitConstArray ();
	} else this._lex.rewind ();
	
	auto var = visitVar ();
	auto next = _lex.next ();
	if (find (_suiteElem, next) != []) 
	    return visitSuite (next, var);
	else _lex.rewind ();
	return var;
    }

    private Var visitVar () {
	auto ident = visitIdentifiant ();
	return new Var (ident);
    }
    
    private Expression visitConstArray () {
	this._lex.rewind ();
	auto begin = this._lex.next ();
	auto array = new ConstArray (begin);
	auto word = this._lex.next ();
	if (word != Tokens.RCRO) {
	    this._lex.rewind ();
	    array.addParam (visitExpression ());
	    while (true) {
		word = this._lex.next ();
		if (word == Tokens.RCRO) break; 
		else if (word != Tokens.COMA) throw new SyntaxError (word, [Tokens.COMA, Tokens.RCRO]);
		array.addParam (visitExpression ());
	    }	    
	}
	return new ConstArray (begin);
    }

    private Expression visitCast () {
	this._lex.rewind ();
	auto begin = this._lex.next ();
	auto word = this._lex.next (Tokens.LPAR);
	auto next = this._lex.next ();
	auto type = visitType ();
	this._lex.next (Tokens.RPAR);
	auto expr = visitExpression ();
	return new Cast (begin, type, expr);	
    }
    
    private Expression visitSuite (Word token, Expression left) {
	if (token == Tokens.LPAR) return visitPar (left);
	else if (token == Tokens.LCRO) return visitAccess (left);
	else if (token == Tokens.DOT) return visitDot (left);
	else
	    throw new SyntaxError (token);
    }

    /**
     par := '(' (expression (',' expression)*)? ')'
     */
    private Expression visitPar (Expression left) {
	_lex.rewind ();
	auto beg = _lex.next (), next = _lex.next ();
	auto suite = next;
	auto params = new ParamList ();
	if (next != Tokens.RPAR) {
	    _lex.rewind ();
	    while (1) {
		params.addParam (visitExpression ());
		next = _lex.next ();
		if (next == Tokens.RPAR) break;
		else if (next != Tokens.COMA)
		    throw new SyntaxError (next, [Tokens.RPAR, Tokens.COMA]);
	    }
	}
	auto retour = new Par (beg, next, left, params);
	next = _lex.next ();
	if (find (_suiteElem, next) != [])
	    return visitSuite (next, retour);
	else if (find  (_afUnary, next) != [])
	    return visitAfter (next, retour);
	_lex.rewind ();
	return retour;
    }

    /**
     access := '[' (expression (',' expression)*)? ']'
     */
    private Expression visitAccess (Expression left) {
	_lex.rewind ();
	auto beg = _lex.next (), next = _lex.next ();
	auto suite = next;
	auto params = new ParamList ();
	if (next != Tokens.RCRO) {
	    _lex.rewind ();
	    while (1) {
		params.addParam (visitExpression ());
		next = _lex.next ();
		if (next == Tokens.RCRO) break;
		else if (next != Tokens.COMA)
		    throw new SyntaxError (next, [Tokens.RCRO, Tokens.COMA]);
	    }
	}
	auto retour = new Access (beg, next, left, params);
	next = _lex.next ();
	if (find (_suiteElem, next) != [])
	    return visitSuite (next, retour);
	else if (find(_afUnary, next) != [])
	    return visitAfter (next, retour);
	_lex.rewind ();
	return retour;
    }
    
    /**
     dot := '.' identifiant
     */
    private Expression visitDot (Expression left) {
	_lex.rewind ();
	auto begin = _lex.next ();
	auto right = visitVar ();
	auto retour = new Dot (begin, left, right);
	auto next = _lex.next ();
	if (find (_suiteElem, next) != [])
	    return visitSuite (next, retour);
	else if (find (_afUnary, next) != [])
	    return visitAfter (next, retour);
	_lex.rewind ();
	return retour;
    }

    private Expression visitAfter (Word word, Expression left) {
	return new AfUnary (word, left);
    }
    
    
    private Expression visitBeforePth (Word word) {
	auto elem = visitPth ();
	return new BefUnary (word, elem);
    }    

    private TypedVar visitTypeVar () {
	auto type = visitType ();
	auto name = visitIdentifiant ();
	return new TypedVar (type, name);
    }

    private Type visitType (bool need = false) {
	auto ident = visitIdentifiant ();
	auto type = new Type (ident);
	auto next = this._lex.next ();
	if (next == Tokens.LCRO) {
	    next = this._lex.next ();
	    if (next != Tokens.RCRO) {
		type.setLen (visitExpression ());
		this._lex.next (Tokens.RCRO);
	    } else {
		type.isArray = true;
	    }
	} else this._lex.rewind ();
	
	return type;
    }

    Word visitIdentifiant () {
	auto ident = this._lex.next ();
	if (ident.isToken ())
	    throw new SyntaxError (ident, ["'Identifiant'"]);
	
	if (find !"b == a" (this._forbiddenIds, ident) != [])
	    throw new SyntaxError (ident, ["'Identifiant'"]);
	
	if (ident.str.length == 0) throw new SyntaxError (ident, ["'Identifiant'"]);
	auto i = 0;
	foreach (it ; ident.str) {
	    if ((it >= 'a' && it <= 'z') || (it >= 'A' && it <= 'Z')) break;
	    else if (it != '_') throw new SyntaxError (ident, ["'identifiant'"]);
	    i++;
	}
	i++;
	if (ident.str.length < i)
	    throw new SyntaxError (ident, ["'Identifiant'"]);
	
	foreach (it ; ident.str [i .. $]) {
	    if ((it < 'a' || it > 'z')
		&& (it < 'A' || it > 'Z')
		&& (it != '_')
		&& (it < '0' || it > '9'))
		throw new SyntaxError (ident, ["'Identifiant'"]);
	}
	
	return ident;
    }

}
