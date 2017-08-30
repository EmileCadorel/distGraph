import std.stdio;

import openclD._;
import std.file, std.stdio;
struct Test {
    int b;
    int i;
}


enum LEN = 10L;

void main () {
    alias lmbd = Lambda!((a, b)=> writeln ((a + b))
, "(a, b)=> writeln ((a + b))
")
;
    lmbd.call (12, 10);
}
