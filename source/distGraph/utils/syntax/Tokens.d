module distGraph.utils.syntax.Tokens;

struct Token {
    string  descr;
    ulong id;
}

struct Tokens {
    
    static Token DPOINT () {
	return Token (":", 0);
    }
    
    static Token DIESE () {
	return Token ("#", 1);
    }
    
    static Token EXL () {
	return Token ("!", 2);
    }
    
    static Token GPAR () {
	return Token ("(", 3);
    }
    
    static Token DPAR () {
	return Token (")", 4);
    }
    
    static Token SPACE () {
	return Token (" ", 5);
    }
    
    static Token RET () {
	return Token ("\n", 6);
    }
    
    static Token RRET () {
	return Token ("\r", 7);
    }
    
    static Token VIRG () {
	return Token (",", 8);
    }

    static Token [] alls () {
	return [
	    DPOINT, DIESE, EXL, GPAR, DPAR, SPACE, RET, RRET, VIRG
	];
    }
}
