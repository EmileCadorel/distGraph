module semantic.Visitor;
import ast._;
import semantic._;
import syntax._;
import semantic.types._;
import std.algorithm;
import std.outbuffer;
import utils.DSLException;
import std.stdio, std.container;

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


void declare (Program prog) {
    foreach (it ; prog.strs) {
	TABLE.addStr (it);
    }

    foreach (it ; prog.funcs) {
	TABLE.addFunc (it);
    }
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
	(Dot dot) => validate (dot)
    );
}

void validate (Binary bin) {
    auto binaryOp = [Tokens.DIV, Tokens.AND, Tokens.DAND, Tokens.PIPE,
		     Tokens.DPIPE, Tokens.MINUS, Tokens.PLUS, Tokens.INF,
		     Tokens.SUP, Tokens.SUP_EQUAL, Tokens.INF_EQUAL,
		     Tokens.NOT_EQUAL, Tokens.DEQUAL, Tokens.XOR];

    auto affOp = [Tokens.DIV_AFF, Tokens.STAR_EQUAL, Tokens.PLUS_AFF, Tokens.MINUS_AFF, Tokens.EQUAL];

    validate (bin.left);
    validate (bin.right);
    
    if (binaryOp.find (bin.token.str) != [])
	bin.sym = new Symbol (bin.token, bin.left.type.binaryOp (bin.token.str, bin.right.type));
    else if (affOp.find (bin.token.str) != [])
	bin.sym = new Symbol (bin.token, bin.left.type.affOp (bin.token.str, bin.right.type));
    
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
    if (sym is null) throw new UndefVar (v.token);
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
    toFile (prg.replace, mkdirGen (filename));
}

/++
 Génére les sources qui vont être compilé par OpenCL.
 +/
string target () {
    auto buf = new OutBuffer ();
    foreach (it ; TABLE.allStructs ()) {
	buf.writefln ("%s", it.toString);
    }

    foreach (it ; TABLE.allFunctions ()) {
	buf.writefln ("%s", it.toString);
    }
    
    return buf.toString ();
}
