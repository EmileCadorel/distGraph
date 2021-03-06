module distGraph.assign.ssh.connect_ssh;

import std.stdio;

import libssh.session;
import libssh.errors;

import distGraph.assign.ssh.knownhosts;
import distGraph.assign.ssh.authentication;

SSHSession sessionConnect(string host, string user, LogVerbosity verbosity) {
    try {
        auto session = new SSHSession();
        scope(failure) session.dispose();

        if (user !is null) {
            session.user = user;
        }

        session.host = host;
        session.logVerbosity = verbosity;

        session.connect();

        if (!verifyKnownhost(session)) {
            session.dispose();
            return null;
        }

        auto auth = authenticateConsole(session);
        if (auth == AuthState.Success) {
            return session;
        } else if (auth == AuthState.Denied) {
            stderr.writeln("Authentication failed");
        } else {
            stderr.writefln("Error while authenticating : %s", session.lastError);
        }
        session.dispose();
        return null;
    } catch (SSHException sshException) {
        stderr.writefln("Error while session connect. Code = %d, Message:\n%s\n",
            sshException.errorCode, sshException.msg);
        return null;
    }
}

SSHSession sessionConnect(string host, string user, string pass, LogVerbosity verbosity) {
    try {
        auto session = new SSHSession();
        scope(failure) session.dispose();

        if (user !is null) {
            session.user = user;
        }

        session.host = host;
        session.logVerbosity = verbosity;

        if (!session.connect()) {
	    return null;
	}
	
        if (!verifyKnownhost(session)) {
            session.dispose();
            return null;
        }
	
	if (pass is null) pass = "";	
        auto auth = authenticatePassword(session, pass);
        if (auth == AuthState.Success) {
            return session;
        } else if (auth == AuthState.Denied) {
            stderr.writeln("Authentication failed");
        } else {
            stderr.writefln("Error while authenticating : %s", session.lastError);
        }
        session.dispose();
        return null;
    } catch (SSHException sshException) {
        stderr.writefln("Error while session connect. Code = %d, Message:\n%s\n",
            sshException.errorCode, sshException.msg);
        return null;
    }
}

