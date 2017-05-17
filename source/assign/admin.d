module assign.admin;
import std.traits;
import utils.Options;
public import assign.launching;
import assign.socket.Protocol;
import std.stdio, std.conv, std.string;
import std.format, assign.fork;

static __gshared bool __assignAdmLaunched__ = false;

/++
 Exception jeté, lorsque plusieurs instance d'admin sont créées
+/
class AssignAdminMultiple : Exception {
    this () {
	super ("Cannot define mutiple administrator");
    }    
}

bool assignContext () {
    return __assignAdmLaunched__;
}


private bool checkC (T ...) () {
    foreach (i, t1 ; T) {
	static assert ((is (typeof(&t1) U : U*) && is (U == function)) ||
		       (is (t1 T2) && is(T2 == function)));       
	alias a1 = ParameterTypeTuple!(t1);
	alias r1 = ReturnType!(t1);
	static assert (a1.length == 0 && is(r1 == void));	
    }
    return true;
}

private bool checkF (T ...) () {
    foreach (i, t1 ; T) {
	static assert ((is (typeof(&t1) U : U*) && is (U == function)) ||
		       (is (t1 T2) && is(T2 == function)));       
	alias a1 = ParameterTypeTuple!(t1);
	alias r1 = ReturnType!(t1);
	static assert (a1.length == 2 && is (a1 [0] : Mid) && is (a1[1] : uint) && is(r1 == int));	
    }
    return true;
}


class AssignAdmin (P : Protocol, alias console) 
    if (checkC!(console)) {

    private uint[] _forks;

    
    this (string [] args) {
	if (assignContext) throw new AssignAdminMultiple ();
	__assignAdmLaunched__ = true;
	Options.init (args);
	// L'instance est lancé depuis l'exterieur par connexion ssh
	if (Options.active ("--ip")) {	    
	    writeln (format ("Lancement de l'instance depuis %s(%s:%s) en tant que %s",
			     Options ["--ip"],
			     Options ["--port"],
			     Options ["--id"],
			     Options ["--tid"])
	    );

	    stdout.flush ();	   
	    Server.machineId = Options ["--tid"].to!uint;

	    Server.start ();
	    Server.setProtocol (new P);
	    
	    Server.handShake (Options ["--ip"],
			      Options ["--port"].to!ushort,
			      Options ["--id"].to!uint);
	    
	    console ();
	} else {	    
	    Server.setProtocol (new P);
	    
	    if (Options.active ("--hosts")) {
		try {
		    import std.file, std.json;
		    auto json = parseJSON (readText (Options ["--hosts"]));
		    foreach (it ; json ["machines"].array) {
			auto user = it ["user"].str.strip;
			auto pass = it ["pass"].str.strip;
			auto ip = it ["ip"].str.strip;
			auto path = it ["path"].str.strip;
			writefln ("Lancement d'une nouvelle instance sur %s@(%s:%s) -p %s",
				  user, ip, path, pass);
			launchInstance (user, ip, pass, path);
		    }
		} catch (Exception e) {
		    writeln ("Le fichier host est corrompu ", e.msg);
		}
	    }
	    console ();
	}	
    }

    void join () {
	import frk = assign.fork;
	Server.join ();
	foreach (i ; 0 .. this._forks.length) {
	    send (cast(uint) i, "end");	    
	}
	
	frk.join (this._forks);
    }

}



