import std.stdio;

template Machin (string fun) {
    int Machin() {
	writeln (fun);
	return 0;
    }
}

void main () {
    auto a = Machin! (
"  (int a) {
      for (auto i = 0; (i < 100) ; i++) {
          a++;
          writeln (a);
      }
      return a;
  }"    );    
}
