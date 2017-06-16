module assign.admin;
import std.traits;
import utils.Options;
public import assign.launching;
import assign.socket.Protocol;
import std.stdio, std.conv, std.string;
import std.format, assign.fork;
import core.stdc.stdlib;

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

class AssignAdmin {

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
	    Server.handShake (Options ["--ip"],
			      Options ["--port"].to!ushort,
			      Options ["--id"].to!uint);
	    this.join ();
	    exit (0);
	} else {	    	    
	    if (Options.active ("--hosts") || Options.active ("-h")) {
		string name;
		if (Options.active ("-h")) name = Options ["-h"];
		else name = Options ["--hosts"];
		try {
		    import std.file, std.json;
		    auto json = parseJSON (readText (name));
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
		    throw e;
		}
	    }
	}	
    }
    
    void join () {
	Server.join ();
    }

    void end () {
	Server.kill ();
    }

}


