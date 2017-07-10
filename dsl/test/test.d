import std.stdio;

template Machin (alias fun) {
    int Machin() {
	writeln (fun (123));
	return 0;
    }
}

void main () {
    auto a = Machin! (
	fn (int a) {
	    for (auto i = 0 ; i < 100; i++) {
		a++;
		writeln (a);
	    }
	    return a;
	}	
    );    
}
