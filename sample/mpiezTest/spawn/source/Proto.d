import mpiez.Process;
import mpiez.Message;

class Proto : Protocol {

    this (int id, int total) {
	super (id, total);
	this.hi = new Message!(1, string);
	this.se = new Message!(2, ulong[]);
    }


    Message!(1, string) hi;
    Message!(2, ulong[]) se;
}
