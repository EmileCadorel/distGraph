module assign.launching;
import std.stdio;
import libssh.session;
import libssh.channel;
import libssh.errors;
import libssh.key;
import libssh.utils;
import std.string;

import assign.ssh.connect_ssh;

/++
 Lance une instance du programme sur une machine distante
 Etablis une connexion tcp/ip avec elle.
+/
void launchInstance (string username, string ip, string pass) {

    scope (exit) sshFinalize ();

    auto session = sessionConnect (ip, username, LogVerbosity.NoLog);
    if (session is null) {
	assert (false, "Connexion failed");
    }

    try {

	auto channel = session.newChannel();
        scope(exit) channel.dispose();

        channel.openSession();
        scope(exit) channel.close();

        channel.requestExec("lsof");
        scope(exit) channel.sendEof();

        char[256] buffer;
        auto nbytes = channel.read(buffer, false);
        while (nbytes > 0) {
            stdout.write(buffer[0 .. nbytes]);
            nbytes = channel.read(buffer, false);
	}
	
    } catch (SSHException ssh) {
	stderr.writefln("SSH exception. Code = %d, Message:\n%s\n",
			ssh.errorCode, ssh.msg);
	throw ssh;
    }    
}



