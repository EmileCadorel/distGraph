import std.stdio;
import openclD._;
import std.file, std.stdio;
import dsl._;
import openclD._;
import std.file, std.stdio;

auto all = q{
    struct Test {
	int b;
	int i;
    }
    
    }
};

enum LEN = 10L;

void main () {
    auto kernel = new Visitor (all).visit ();
    
}
