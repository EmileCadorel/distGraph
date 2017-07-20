module syntax.Tokens;
import std.typecons;

alias Token = string;

enum Tokens : Token {
    DIV = ("/"), 
    DIV_AFF = ("/="),
    DOT = ("."),
    DDOT = (".."),
    TDOT = ("..."),
    AND = ("&"),
    AND_AFF = ("&="),
    DAND = ("&&"),
    PIPE = ("|"),
    PIPE_EQUAL = ("|="),
    DPIPE = ("||"),
    MINUS = ("-"),
    MINUS_AFF = ("-="),
    DMINUS = ("--"),
    PLUS = ("+"),
    PLUS_AFF = ("+="),
    DPLUS = ("++"),
    INF = ("<"),
    INF_EQUAL = ("<="),
    LEFTD = ("<<"),
    LEFTD_AFF = ("<<="),
    SUP = (">"),
    SUP_EQUAL = (">="),
    RIGHTD_AFF = (">>="),
    RIGHTD = (">>"),
    NOT = ("!"),
    NOT_EQUAL = ("!="),
    NOT_INF = ("!<"),
    NOT_INF_EQUAL = ("!<="),
    NOT_SUP = ("!>"),
    NOT_SUP_EQUAL = ("!>="),
    LPAR = ("("),
    RPAR = (")"),
    LCRO = ("["),
    RCRO = ("]"),
    LACC = ("{"),
    RACC = ("}"),
    INTEG = ("?"),
    COMA = (","),
    SEMI_COLON = (";"),
    COLON = (":"),
    DOLLAR = ("$"),
    EQUAL = ("="),
    DEQUAL = ("=="),
    STAR = ("*"),
    STAR_EQUAL = ("*="),
    PERCENT = ("%"),
    PERCENT_EQUAL = ("%="),
    XOR = ("^"),
    XOR_EQUAL = ("^="),
    DXOR = ("^^"),
    DXOR_EQUAL = ("^^="),
    TILDE = ("~"),
    TILDE_EQUAL = ("~="),
    AT = ("@"),
    IMPLIQUE = ("=>"),
    SHARP = ("#"),
    SPACE = (" "),
    RETOUR = ("\n"),
    RRETOUR = ("\r"),
    GUILL = ("\""),
    APOS = ("'"),
    TAB = ("\t"),
    ARROW = ("->"),
    DCOLON = ("::"),
    LCOMM1 = ("//"),
    LCOMM2 = ("/*"),
    RCOMM2 = ("*/")
}    

