module utils.Singleton;

/**
 mixin permettant a une classe de devenir Singleton
 Securise entre Thread
 */
mixin template Singleton (T) {

    static ref T instance () {
	if (inst is null) {
	    synchronized {
		if (inst is null) {
		    inst = new T;
		}
	    }
	}
	return inst;
    }

private:

    __gshared static T inst = null;

}
