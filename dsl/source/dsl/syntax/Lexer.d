module dsl.syntax.Lexer;
import dsl.syntax.Word;
import dsl.utils.DSLException;
import dsl.syntax.Tokens;
import std.container, std.traits;
import std.stdio, std.file, std.string;
import dsl.syntax.SyntaxError;

class LexerError : DSLException {
    this (string filename) {
	super (filename ~ " n'est pas un fichier");
    }
}

/**
 Classe de decoupage de fichier par token
 T doit etres un enum
 */
class Lexer {

    this (Token [] skips, Token[2][] comments) {
	this._line = 1;
	this._column = 1;
	this._tokens = [EnumMembers!Tokens];
	foreach (it ; skips) 
	    this._skips[it] = true;
	this._comments = comments;
	this._current = -1;
	this._enableComment = true;
    }
    
    this (string filename, Token [] skips, Token[2][] comments) {
	this._line = 1;
	this._column = 1;
	this._tokens = [EnumMembers!Tokens];
	foreach (it ; skips) 
	    this._skips[it] = true;
	this._comments = comments;
	this._current = -1;
	this._enableComment = true;
	
	this._filename = filename;
	try {
	    if (filename.isDir)
		throw new LexerError (filename);
	    this._file = File (filename, "r");
	} catch (Throwable o) {
	    throw new LexerError (filename);
	}
    }

    /**
     Le nom du fichier courant
     */
    string filename () const {
	return this._filename;
    }

    /**
     Active un token skip
     Params:
           elem = le token a passe
	   on = active ou non     
    */
    void skipEnable (Token elem, bool on = true) {
	this._skips [elem] = on;
    }

    /**
     Active la suppression des commentaire
     Params:
     on = active ou desactive
     */
    void commentEnable (bool on = true) {
	this._enableComment = on;
    }
        
    /**
     Recupere le mot suivant
     Params:
     word = le mot a retourner par reference
     Return le lexer
     */
    Lexer next (ref Word word) {
	if (this._current >= cast(long) (this._reads.length - 1)) {
	    return this.get (word);
	} else {
	    this._current ++;
	    word = this._reads [this._current];
	    return this;
	}
    }

    /**
     Recupere le mot suivant
     Return:
     le mot lu
     */
    Word next () {
	Word word;
	this.next (word);
	return word;
    }

    /**
     Recupere le mot 
     Return: le mot lu
     Throws: SyntaxError, si le mot n'est pas un de ceux passé en param
     */
    Word next (T...) (T params) {
	Word word;
	this.next (word);
	foreach (Token it ; params)
	    if (word == it) return word;
	string [] need = new string [params.length];
	foreach (i, it ; params)
	    need [i] = it;
	throw new SyntaxError (word, need);
    }
   
    
    /**
     Retour en arriere dans le fichier
     */
    Lexer rewind (ulong nb = 1) {
	this._current -= nb;
	return this;
    }

    ulong tell () {
	return this._current;
    }

    void seek (ulong where) {
	this._current = where;
    }
    
    
    protected Lexer get (ref Word word) {
	do {
	    if (!getWord (word)) {
		word.setEof ();
		break;
	    } else {
		Token com;
		while (isComment (word, com) && _enableComment) {
		    do {
			getWord (word);
		    } while (word != com && !word.isEof);
		    getWord (word);
		}
	    }	    
	} while (isSkip (word) && !word.isEof);
	
	this._reads.insertBack (word);	
	this._current ++;
	
	return this;
    }

    protected bool isComment (Word elem, ref Token retour) {
	foreach (it ; this._comments) {
	    if (it[0] == elem.str) {
		retour = it [1];
		return true;
	    }
	}
	return false;
    }

    protected bool isSkip (Word elem) {
	foreach (key, value ; this._skips) {
	    if (key == elem.str && value) return true;
	}
	return false;
    }
    
    protected bool getWord (ref Word word) {
	if (this._file.eof ()) return false;
	auto where = this._file.tell ();
	auto line = this._file.readln ();
	if (line is null) return false;
	ulong max = 0, beg = line.length;
	foreach (it ; this._tokens) {
	    auto id = indexOf (line, it);
	    if (id != -1) {
		if (id == beg && it.length > max)  max = it.length;
		else if (id < beg) {
		    beg = id;
		    max = it.length;
		}
	    }
	}
	constructWord (word, beg, max, line, where);
	if (word.str == "\n" || word.str == "\r") {
	    this._line ++;
	    this._column = 1;
	} else {
	    this._column += word.str.length;
	}
	
	return true;
    }

    protected ulong min(ulong u1, ulong u2) {
	return u1 < u2 ? u1 : u2;
    }
    
    protected void constructWord (ref Word word, ulong beg, ulong _max, string line, ulong where) {	
	if (beg == line.length + 1) word.str = line;
	else if (beg == 0) {
	    word.str = line [0 .. min(_max, line.length)];
	    this._file.seek (where + _max);
	} else if (beg > 0) {
	    word.str = line [0 .. min(beg, line.length)];
	    this._file.seek (where + beg);
	}
	word.locus = Location (this._line, this._column, word.str.length, this._filename);
    }
    
    bool isMixinContext () {
	return false;
    }
    
    ~this () {
	this._file.close ();
    }
    
    protected Token [] _tokens;
    protected bool [Token] _skips;
    protected Token [2][] _comments;
    protected string _filename;
    protected bool _enableComment;
    protected Array!(Word) _reads;
    protected long _current;
    protected File _file;
    protected ulong _line;
    protected ulong _column;
    
}



class StringLexer : Lexer {

    private string _content;

    private ulong _beg = 0;
    
    this (string content, Token [] skips, Token[2][] comments) {
	super (skips, comments);
	this._content = content;
    }
    
    protected override bool getWord (ref Word word) {
	if (this._beg >= this._content.length) return false;
	auto where = this._beg;
	auto line = this._content [this._beg .. $];
	ulong max = 0, beg = line.length;
	foreach (it ; this._tokens) {
	    auto id = indexOf (line, it);
	    if (id != -1) {
		if (id == beg && it.length > max)  max = it.length;
		else if (id < beg) {
		    beg = id;
		    max = it.length;
		}
	    }
	}
	constructWord (word, beg, max, line, where);
	if (word.str == "\n" || word.str == "\r") {
	    this._line ++;
	    this._column = 1;
	} else {
	    this._column += word.str.length;
	}
	
	return true;
    }    
    
    protected override void constructWord (ref Word word, ulong beg, ulong _max, string line, ulong where) {
	import dsl.syntax.Keys;
	if (beg == line.length + 1) {
	    this._beg += line.length;
	    word.str = line;
	} else if (beg == 0) {
	    word.str = line [0 .. min(_max, line.length)];
	    this._beg = (where + _max);
	} else if (beg > 0) {
	    word.str = line [0 .. min(beg, line.length)];
	    this._beg = (where + beg);
	}
	word.locus = Location (this._line, this._column, word.str.length, Keys.MIXIN, this._content);
    }

    override bool isMixinContext () {
	return true;
    }
    
}
