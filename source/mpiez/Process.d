module mpiez.Process;
public import mpiez.Message;

class Protocol {
    private int _id;
    
    private int _total;

    this (int id, int total) {
	this._id = id;
	this._total = total;	
    }

    const (int) id () const {
	return this._id;	
    }

    const (int) total () const {
	return this._total;
    }
    
}

class Process (P : Protocol) {

    protected P _proto;
    
    this (string [] args, P proto) {
	this._proto = proto;
    }

    const (int) thisId () const {
	return this._proto.id;
    }

    const (int) worldNb () const {
	return this._proto.total;
    }
    
    abstract void routine ();

    abstract void onEnd ();

}
