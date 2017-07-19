module semantic.Visitor;
import ast._;
import semantic._;
import syntax._;
import semantic.types._;
import std.algorithm;
import std.outbuffer;
import utils.DSLException;

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
    foreach (it ; TABLE.allFunctions) {
	validate (it);
    }
}

void validate (Function func) {
    TABLE.enterBlock ();
    foreach (it ; func.params) {
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
	(Binary bin) => validate (bin)
    );
}

void validate (Expression expr) {
    expr.match (
	(Binary bin) => validate (bin),
	(Access acc) => validate (acc),
	(Var v) => validate (v),
	(Decimal dc) => validate (dc),
	(Float fl) => validate (fl)
    );
}

void validate (Binary bin) {
    auto binaryOp = [Tokens.DIV, Tokens.AND, Tokens.DAND, Tokens.PIPE,
		     Tokens.DPIPE, Tokens.MINUS, Tokens.PLUS, Tokens.INF,
		     Tokens.SUP, Tokens.SUP_EQUAL, Tokens.INF_EQUAL,
		     Tokens.NOT_EQUAL, Tokens.DEQUAL, Tokens.XOR];

    auto affOp = [Tokens.DIV_AFF, Tokens.STAR_EQUAL, Tokens.PLUS_AFF, Tokens.MINUS_AFF];

    validate (bin.left);
    validate (bin.right);
    if (binaryOp.find (bin.token.str))
	bin.sym = new Symbol (bin.token, bin.left.type.binaryOp (bin.token.str, bin.right.type));
    else if (affOp.find (bin.token.str))
	bin.sym = new Symbol (bin.token, bin.left.type.affOp (bin.token.str, bin.right.type));
    else {
	bin.sym = new Symbol (bin.token, bin.right.type.clone ());
	bin.left.type = bin.right.type.clone ();
    }
    
    if (bin.type is null) throw new UndefinedOp (bin.token, bin.left.type, bin.right.type);
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

void validate (TypedVar var) {
    auto type = getType (var.type);
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
    default: assert (false, "TODO " ~ type.ident.str);
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
