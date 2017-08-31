import std.stdio;
import dsl._;
import CL = openclD._;

auto all = q{
    struct Test {
	int b;
	int i;
    }
    
    __skel map (T, alias FUN) (T [] a, ulong size) {
	auto i = get_global_id (0);
	if (i < size)
	    a [i] = FUN (a [i]);
    }
};

enum LEN = 10L;

void main () {
    auto src = new Visitor (all, false).visit ();
    auto map = src.getSkel ("map");
    TABLE.addSkel (map);

    auto inline = new Inline ("map");
    inline.addTemplate (new Var ("int"));
    
    auto lmbd = new Visitor (CL.Lambda! ((a) => a + 1,
					 "a => a + 1").toString
			     , false).visitLambda ();
    inline.addTemplate (lmbd);

    sem.createFunc (map, inline);    
    auto kernel = new CL.Kernel (sem.target (), "map0");
    auto a = new CL.Vector!(int) ([1, 2, 3]);
    
    kernel (1, 3, a, a.length);
    writeln (a);
}
