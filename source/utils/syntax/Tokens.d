module utils.syntax.Tokens;

struct Token {
    string  descr;
    ulong id;
}

enum Tokens  {
    DPOINT = Token (":", 0),
    DIESE = Token ("#", 1),
    EXL = Token ("!", 2),
    GPAR = Token ("(", 3),
    DPAR = Token (")", 4),
    SPACE = Token (" ", 5),
    RET = Token ("\n", 6),
    RRET = Token ("\r", 7),
    VIRG = Token (",", 8)
}
