import std.stdio;
import assign.Lambda;

void main() {
    alias lmbd = Lambda!((int a, int b) => writeln (a + b),
			"(int a, int b) => writeln (a + b)");
    lmbd.call (10, 12);
    writeln (lmbd.toString);
    
}
