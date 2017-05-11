module assign.admin;
import std.traits;
import utils.Options;
public import assign.launching;
import assign.socket.Protocol;
import std.stdio, std.conv, std.string;
import std.format;

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


private bool checkT (T ...) () {
    foreach (i, t1 ; T) {
	static assert ((is (typeof(&t1) U : U*) && is (U == function)) ||
		       (is (t1 T2) && is(T2 == function)));       
	alias a1 = ParameterTypeTuple!(t1);
	alias r1 = ReturnType!(t1);
	static assert (a1.length == 0 && is(r1 == void));	
    }
    return true;
}

class AssignAdmin (P : Protocol, alias fun) 
    if (checkT!(fun)) {
    
    this (string [] args) {
	if (assignContext) throw new AssignAdminMultiple ();
	__assignAdmLaunched__ = true;
	Server.setProtocol (new P);
	Server.start ();
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
	    
	    Server.handShake (Options ["--ip"],
			      Options ["--port"].to!ushort,
			      Options ["--id"].to!uint);
	    
	    fun ();
	} else {
	    writeln ("la");
	    stdout.flush ();
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
	    fun ();
	}	
    }

    void join () {
	Server.join ();
    }

}



