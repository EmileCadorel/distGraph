module dsl.semantic.Visitor;
import dsl.ast._;
import dsl.semantic._;
import dsl.syntax._;
import dsl.semantic.types._;
import std.algorithm;
import std.outbuffer;
import dsl.utils.DSLException;
import std.stdio, std.container, std.conv;

class UndefinedOp : DSLException {

    this (Word op, InfoType left, InfoType right) {
	auto buf = new OutBuffer ();
	buf.writefln ("Pas d'operateur %s, pour les types (%s) et (%s)",
		      op.str,
		      left.toString,
		      right.toString
	);
	super.addLine (buf, op.locus);
	this.msg = buf.toString;
    }

    this (Word begin, Word end, InfoType left, Array!Expression right) {
	auto buf = new OutBuffer;
	buf.writef ("Par d'operateur (), pour les types : (%s) et (",
		    left.toString
	);
	foreach (it ; right)
	    buf.writef ("%s%s", it.toString, it is right[$ - 1] ? "" : ", ");
	buf.writefln (")");
	super.addLine (buf, begin.locus, end.locus);
	this.msg = buf.toString;
    }

    this (Word op, InfoType left, string name) {
	auto buf = new OutBuffer;
	buf.writefln ("Pas d'attribut %s, pour le type %s",
		      name, left.toString);
	super.addLine (buf, op.locus);
	this.msg = buf.toString;
    }

    this (Word op, InfoType left) {
	auto buf = new OutBuffer;
	buf.writefln ("Pas d'operateur %s, pour le type %s",
		      op.str, left.toString);
	super.addLine (buf, op.locus);
	this.msg = buf.toString;
    }

    
}

class IncompType : DSLException {

    this (string type, InfoType type2, Word loc) {
	auto buf = new OutBuffer;
	buf.writefln ("Type incompatible (%s) et (%s",
		      type, type2.toString);
	super.addLine (buf, loc.locus);
	this.msg = buf.toString;
    }
    

}

class UndefVar : DSLException {

    this (Word var) {
	auto buf = new OutBuffer ();
	buf.writefln ("Variable inconnu : %s",
		      var.str);
	super.addLine (buf, var.locus);
	this.msg = buf.toString;
    }    

}

class MultipleDef : DSLException {

    this (Word fst, Word scd) {
	auto buf = new OutBuffer;
	buf.writefln ("La variable %s, est déjà définis", fst.str);
	super.addLine (buf, scd.locus);
	buf.writefln ("Première définition :");
	super.addLine (buf, fst.locus);
	this.msg = buf.toString;
    }
    
}

class UndefinedKernel : DSLException {

    this (Word kern) {
	auto buf = new OutBuffer;
	buf.writefln ("Le kernel %s n'existe pas", kern.str);
	super.addLine (buf, kern.locus);
	this.msg = buf.toString;
    }

}

class ErrorCreation : DSLException {

    this (Word kern) {
	auto buf = new OutBuffer;
	buf.writefln ("La création du kernel à partir du squelette %s ne fonctionne pas",
		      kern.str);
	super.addLine (buf, kern.locus);
	this.msg = buf.toString;
    }
    
}

void declare (Program prog) {
    foreach (it ; prog.strs) {
	TABLE.addStr (it);
    }

    foreach (it ; prog.skels) {
	TABLE.addSkel (it);
    }
    
    foreach (it ; prog.funcs) {
	TABLE.addFunc (it);
    }

    TABLE.addProg (prog);
}

void match (U, T...) (U inst, T funcs) {
    import std.traits;
    foreach (func ; funcs) {
	static assert (ParameterTypeTuple!(func).length == 1);
	alias tuple = ParameterTypeTuple!(func) [0];
	if (auto tu = cast (tuple) inst) {
	    func (tu); return; 
	}
    }
    assert (false, "TODO " ~ typeid (inst).toString);
}

auto matchRet (U, T...) (U inst, T funcs) {
    import std.traits;
    foreach (func ; funcs) {
	static assert (ParameterTypeTuple!(func).length == 1);
	alias tuple = ParameterTypeTuple!(func) [0];
	if (auto tu = cast (tuple) inst) {
	    return func (tu); 
	}
    }
    assert (false, "TODO " ~ typeid (inst).toString);    
}

void validate () {
    foreach (it ; TABLE.allStructs) {
	validate (it);
    }

    foreach (it ; TABLE.allFunctions) {
	validate (it);
    }
}

void validate (Struct str) {
    TABLE.enterBlock ();

    foreach (it ; str.params)
	validate (it);
    
    TABLE.quitBlock ();
}

void validate (Function func) {
    TABLE.enterBlock ();
    foreach (ref it ; func.params) {
	validate (it);
    }

    validate (func.block);
    
    TABLE.enterBlock ();
}

void validate (Block block) {
    TABLE.enterBlock ();
    foreach (it ; block.insts) {
	validate (it);
    }    
    TABLE.quitBlock ();
}
       
void validate (Instruction inst) {
    inst.match (
	(Binary bin) => validate (bin),
	(Auto _au) => validate (_au),
	(For _for) => validate (_for),
	(If _if) => validate (_if)
    );
}

void validate (Expression expr) {
    expr.match (
	(Binary bin) => validate (bin),
	(Access acc) => validate (acc),
	(Var v) => validate (v),
	(Decimal dc) => validate (dc),
	(Float fl) => validate (fl),
	(Par par) => validate (par),
	(Dot dot) => validate (dot),
	(AfUnary _af) => validate (_af),
	(BefUnary _bef) => validate (_bef)
    );
}

void validate (AfUnary _af) {
    validate (_af.expr);
    _af.sym = new Symbol (_af.token, _af.expr.type.unaryOp (_af.token.str));
    if (_af.type is null) throw new UndefinedOp (_af.token, _af.expr.type);
}

void validate (BefUnary _bef) {
    validate (_bef.expr);
    _bef.sym = new Symbol (_bef.token, _bef.expr.type.unaryOp (_bef.token.str));
    if (_bef.type is null) throw new UndefinedOp (_bef.token, _bef.expr.type);
}


void validate (Binary bin) {
    auto affOp = [Tokens.DIV_AFF, Tokens.STAR_EQUAL, Tokens.PLUS_AFF, Tokens.MINUS_AFF, Tokens.EQUAL];

    validate (bin.left);
    validate (bin.right);
    
    if (affOp.find (bin.token.str) != [])
	bin.sym = new Symbol (bin.token, bin.left.type.affOp (bin.token.str, bin.right.type));
    else
	bin.sym = new Symbol (bin.token, bin.left.type.binaryOp (bin.token.str, bin.right.type));
    
    if (bin.type is null) throw new UndefinedOp (bin.token, bin.left.type, bin.right.type);
}

void validate (Par par) {
    validate (par.left);
    foreach (it ; par.params.params) {
	validate (it);
    }
    
    auto type = par.left.type.parOp (par.params);
    if (type is null) throw new UndefinedOp (par.begin, par.end, par.left.type, par.params.params);
    par.sym = new Symbol (par.begin, type);
}

void validate (Dot dot) {
    validate (dot.left);
    auto type = dot.left.type.dotOp (dot.right.token.str);
    if (type is null) throw new UndefinedOp (dot.token, dot.left.type, dot.right.token.str);
    dot.sym = new Symbol (dot.token, type);
}

void validate (For _for) {
    validate (_for.begin);
    validate (_for.test);
    if (!cast (BoolInfo) _for.test.type) throw new IncompType ("bool", _for.test.type, _for.test.token);
    foreach (it ; _for.iter)
	validate (it);

    TABLE.enterBlock ();
    validate (_for.block);
    TABLE.quitBlock ();
}

void validate (If _if) {
    if (_if.test !is null) {
	validate (_if.test);
	if (!cast (BoolInfo) _if.test.type) throw new IncompType ("bool", _if.test.type, _if.test.token);
	
	TABLE.enterBlock ();
	validate (_if.block);
	TABLE.quitBlock ();

	if (_if.else_) validate (_if.else_);		
    }
}

void validate (Auto _auto) {
    foreach (it ; 0 .. _auto.rights.length) {
	validate (_auto.rights [it]);
	auto sym = TABLE.get (_auto.vars [it].token.str);
	if (sym !is null) throw new MultipleDef (sym.token, _auto.vars [it].token);
	else {
	    sym = new Symbol (_auto.vars [it].token, _auto.rights [it].type.clone ());
	    _auto.vars [it].sym = sym;
	    TABLE.add (sym);
	}
    }
}

void validate (Access acc) {
    validate (acc.left);
    validate (acc.right);
    acc.sym = new Symbol (acc.token, acc.left.type.accessOp (acc.right.type));
}

void validate (Var v) {
    auto sym = TABLE.get (v.token.str);
    if (sym is null) {
	auto str = TABLE.getStruct (v.token.str);
	if (str is null)
	    throw new UndefVar (v.token);
	else {	    
	    v.sym = new Symbol (v.token, new StructCstInfo (str));
	}
    }
    else v.sym = sym;
}

void validate (Decimal dc) {
    dc.sym = new Symbol (dc.token, new IntInfo (IntSize.INT));
}

void validate (Float fl) {
    fl.sym = new Symbol (fl.token, new FloatInfo (FloatSize.DOUBLE));
}

void validate (ref TypedVar var) {
    auto type = getType (var.type);
    var.type.info = type;
    auto sym = new Symbol (var.ident, type);
    TABLE.add (sym);
}

InfoType getType (Type type) {
    if (type.isArray) return new ArrayInfo (getTypeSimple (type));
    else return getTypeSimple (type);
}

InfoType getTypeSimple (Type type) {
    switch (type.ident.str) {
    case "int" : return new IntInfo (IntSize.INT);
    case "long" : return new IntInfo (IntSize.LONG);
    case "ulong" : return new IntInfo (IntSize.ULONG);
    case "uint" : return new IntInfo (IntSize.UINT);
    case "float" : return new FloatInfo (FloatSize.SIMPLE);
    case "double" : return new FloatInfo (FloatSize.DOUBLE);
    case "bool" : return new BoolInfo ();
    default: {
	auto name = TABLE.allStructs[].find!"a.ident.str == b" (type.ident.str);
	if (!name.empty) {
	    return new StructInfo (name [0]);
	}
	assert (false, "TODO " ~ type.ident.str);
    }
    }
}

string mkdirGen (string fl) {
    import std.file, std.algorithm, std.string, std.path;
    mkdirRecurse (buildPath ("out", fl [0 .. fl.lastIndexOf ('/')]));
    return buildPath ("out", fl);
}

void replace (string filename, Program prg) {
    import std.stdio;

    // On valide les appels au différents kernel
    foreach (it ; prg.inlines) {
	validate (it);
    }
    
    toFile (prg.replace, mkdirGen (filename));
}

void validate (Inline inline) {
    auto fun = TABLE.getFunc (inline.what.str);
    if (fun is null) {
	auto skel = TABLE.getSkel (inline.what.str);
	if (skel is null) throw new UndefinedKernel (inline.what);
	else createFunc (skel, inline);
    }    
}

void createFunc (Skeleton skel, Inline inline) {
    if (skel.templates.length + skel.fnNames.length != inline.templates.length && !cast (PreInline) inline) {
	throw new ErrorCreation (inline.what);	
    } else {
	try {
	    auto block = skel.block;
	    auto params = skel.params;
	    auto currentTmp = 0, currentFn = 0;
	    foreach (it ; inline.templates) {	       
		if (auto v = cast (Var) it) {
		    if (currentTmp >= skel.templates.length) throw new ErrorCreation (inline.what);
		    block = replaceEveryWhere (block, skel.templates [currentTmp], v);
		    params = replaceEveryWhere (params, skel.templates [currentTmp], v);		    
		    currentTmp ++;		    
		} else if (auto lm = cast (Lambda) it){
		    if (currentFn >= skel.fnNames.length) throw new ErrorCreation (inline.what);
		    block = inlineLambda (block, skel.fnNames [currentFn], lm);
		    currentFn ++;
		} else assert (false);
	    }
	
	    auto func = new Function (skel.begin, skel.ident);
	    func.ident.str = func.ident.str ~ skel.nbCreated.to!string;
	    inline.what.str = func.ident.str;
	    
	    func.setBlock (block);
	    func.setParams (params);
	    skel.nbCreated ++;	    
	    if (!cast (PreInline) inline)
		validate (func);
	    
	    TABLE.addFunc (func);
	} catch (DSLException dsl) {	    
	    writeln (dsl);
	    throw new ErrorCreation (inline.what);
	}
	
    }
}

Array!TypedVar replaceEveryWhere (Array!TypedVar inParams, Var token, Var var) {
    Array!TypedVar params;
    foreach (it ; inParams) {
	if (it.type.ident.str == token.token.str) {
	    auto type = new Type (var.token);
	    type.isArray (it.type.isArray);	    
	    params.insertBack (new TypedVar (type, it.ident));
	} else {
	    auto type = new Type (it.type.ident);
	    type.isArray = it.type.isArray;
	    params.insertBack (new TypedVar (type, it.ident));
	}
    }
    return params;
}

Block inlineLambda (Block block, Word token, Lambda lmbd) {
    auto ret = new Block (block.token);
    foreach (it ; block.insts) {
	ret.addInst (inlineLambda (it, token, lmbd));
    }
    return ret;
}

Instruction inlineLambda (Instruction inst, Word token, Lambda lmbd) {
    return inst.matchRet (
	(Binary bin) => inlineLambda (bin, token, lmbd),
	(Auto _au) => inlineLambda (_au, token, lmbd),
	(If _if) => inlineLambda (_if, token, lmbd)
    );
}

Instruction inlineLambda (Auto au, Word token, Lambda lmbd) {
    auto aux = new Auto (au.token);
    foreach (it ; 0 .. au.vars.length)
	aux.addInit (new Var (au.vars [it].token),
		     inlineLambda (au.rights [it], token, lmbd));
    
    return aux;    
}

Expression inlineLambda (Expression expr, Word token, Lambda lmbd) {
    return expr.matchRet(
	(Binary bin) => inlineLambda (bin, token, lmbd),
	(Access acc) => inlineLambda (acc, token, lmbd),
	(Par par) => inlineLambda (par, token, lmbd),
	(Dot dot) => inlineLambda (dot, token, lmbd),
	(AfUnary af) => inlineLambda (af, token, lmbd),
	(BefUnary bef) => inlineLambda (bef, token, lmbd),	
	(Expression expr) => expr
    );
}

Expression inlineLambda (AfUnary af, Word token, Lambda lmbd) {
    auto expr = inlineLambda (af.expr, token, lmbd);
    return new AfUnary (af.token, expr);
}

Expression inlineLambda (BefUnary af, Word token, Lambda lmbd) {
    auto expr = inlineLambda (af.expr, token, lmbd);
    return new BefUnary (af.token, expr);
}

Expression inlineLambda (Binary bin, Word token, Lambda lmbd) {
    auto left = inlineLambda (bin.left, token, lmbd);
    auto right = inlineLambda (bin.right, token, lmbd);
    return new Binary (bin.token, left, right);
}

Expression inlineLambda (Access acc, Word token, Lambda lmbd) {
    auto left = inlineLambda (acc.left, token, lmbd);
    auto right = inlineLambda (acc.right, token, lmbd);
    return new Access (acc.begin, acc.end, left, right);
}

Expression inlineLambda (Par par, Word token, Lambda lmbd) {
    if (auto v = cast (Var) par.left) {
	if (v.token.str == token.str) {
	    if (par.params.params.length == lmbd.params.length) {
		Expression content = lmbd.content;
		foreach (it ; 0 .. lmbd.params.length) {
		    content = replaceEveryWhere (content, lmbd.params [it], par.params.params [it]);
		}
		return content;
	    }
	}
    } 
    auto left = inlineLambda (par.left, token, lmbd);
    auto right = inlineLambda (par.params, token, lmbd);
    return new Par (par.begin, par.end, left, right);
}

Expression inlineLambda (Dot dot, Word token, Lambda lmbd) {
    auto left = inlineLambda (dot.left, token, lmbd);
    return new Dot (dot.token, left, dot.right);
}

ParamList inlineLambda (ParamList params, Word token, Lambda lmbd) {
    auto aux = new ParamList ();
    foreach (it ; params.params) {
	aux.addParam (inlineLambda (it, token, lmbd));
    }
    return aux;
}

Instruction inlineLambda (If _if, Word token, Lambda lmbd) {
    Expression test;
    if (_if.test)
	test = inlineLambda (_if.test, token, lmbd);
    auto block = inlineLambda (_if.block, token, lmbd);
    if (_if.else_) {
	auto else_ = cast (If) inlineLambda (_if.else_, token, lmbd);
	auto ret = new If (_if.token, test, block);
	ret.setElse (else_);
	return ret;
    } else
	return new If (_if.token, test, block);
}

Block replaceEveryWhere (Block block, Var token, Expression second) {
    auto aux = new Block (block.token);
    foreach (it ; block.insts) {
	aux.addInst (replaceEveryWhere (it, token, second));
    }
    return aux;
}

Expression replaceEveryWhere (Expression content, Var token, Expression second) {
    return content.matchRet (
	(Binary bin) => replaceEveryWhere (bin, token, second),
	(Access acc) => replaceEveryWhere (acc, token, second),
	(Par par) => replaceEveryWhere (par, token, second),
	(Dot dot) => replaceEveryWhere (dot, token, second),
	(AfUnary af) => replaceEveryWhere (af, token, second),
	(BefUnary bef) => replaceEveryWhere (bef, token, second),
	(Var v) {
	    if (v.token.str == token.token.str) return second;
	    else return v;
	},
	(Expression exp) => exp	
    );
}

Instruction replaceEveryWhere (Instruction inst, Var token, Expression second) {
    return inst.matchRet (
	(Binary bin) => replaceEveryWhere (bin, token, second),
	(Auto au) => replaceEveryWhere (au, token, second),
	(If _if) => replaceEveryWhere (_if, token, second)
    );
}

Instruction replaceEveryWhere (Auto au, Var token, Expression second) {
    auto aux = new Auto (au.token);
    foreach (it ; 0 .. au.vars.length)
	aux.addInit (new Var (au.vars [it].token),
		     replaceEveryWhere (au.rights [it], token, second));

    return aux;
}

Expression replaceEveryWhere (AfUnary af, Var token, Expression second) {
    auto expr = replaceEveryWhere (af.expr, token, second);
    return new AfUnary (af.token, expr);
}

Expression replaceEveryWhere (BefUnary bef, Var token, Expression second) {
    auto expr = replaceEveryWhere (bef.expr, token, second);
    return new BefUnary (bef.token, expr);
}

Expression replaceEveryWhere (Binary bin, Var token, Expression second) {
    auto left = replaceEveryWhere (bin.left, token, second);
    auto right = replaceEveryWhere (bin.right, token, second);
    return new Binary (bin.token, left, right);
}

Expression replaceEveryWhere (Access acc, Var token, Expression second) {
    auto left = replaceEveryWhere (acc.left, token, second);
    auto right = replaceEveryWhere (acc.right, token, second);
    return new Access (acc.begin, acc.end, left, right);
}

Expression replaceEveryWhere (Par par, Var token, Expression second) {
    auto left = replaceEveryWhere (par.left, token, second);
    auto right = replaceEveryWhere (par.params, token, second);
    return new Par (par.begin, par.end, left, right);
}

Expression replaceEveryWhere (Dot dot, Var token, Expression second) {
    auto left = replaceEveryWhere (dot.left, token, second);
    return new Dot (dot.token, left, dot.right);
}

ParamList replaceEveryWhere (ParamList par, Var token, Expression second) {
    auto aux = new ParamList;
    foreach (it ; par.params)
	aux.addParam (replaceEveryWhere (it, token, second));
    return aux;
}

Instruction replaceEveryWhere (If _if, Var token, Expression second) {
    Expression test;
    if (_if.test)
	test = replaceEveryWhere (_if.test, token, second);

    auto block = replaceEveryWhere (_if.block, token, second);
    if (_if.else_) {
	auto _else = cast (If) replaceEveryWhere (_if.else_, token, second);
	auto ret = new If (_if.token, test, block);
	ret.setElse (_else);
	return ret;
    } else {
	return new If (_if.token, test, block);
    }    
}

string targetStruct () {
    auto buf = new OutBuffer ();
    foreach (it ; TABLE.allStructs ()) {
	buf.writefln ("%s", it.toString);
    }
    
    return buf.toString;
}

/++
 génére les sources qui vont être compilé par OpenCL.
 +/
string target () {
    auto buf = new OutBuffer ();
    buf.writefln ("#include \"%s\"\n", TABLE.outFileStructs);
    
    foreach (it ; TABLE.allFunctions ()) {
	buf.writefln ("%s", it.toString);
    }
    
    return buf.toString ();
}
