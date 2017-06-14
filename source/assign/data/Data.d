module assign.data.Data;
import utils.Singleton;
import std.stdio;

alias DataTable = DataTableS.instance;
class DataTableS {

    private DistData [uint] _datas;
    
    void add (DistData data) {
	writeln ("Enregistrement de données d'identifiant ", data.id);
	this._datas [data.id] = data;
    }

    DistData opIndex (uint id) {
	return this._datas [id];
    }

    T get (T : DistData) (uint id) {
	return cast(T) (this._datas [id]);
    }

    void free (uint id) {
	if (auto it = id in this._datas) {
	    delete *it;
	}
    }
    
    void remove (uint id) {
	if (auto it = id in this._datas) {
	    this._datas.remove (id);
	}
    }
    
    mixin ThreadSafeSingleton;
}

abstract class DistData {

    protected uint _id;

        /++
     Les derniers identifiants pour permettre que l'identifiant du tableau soit unique
     +/
    private static uint __lastId__ = 0;

    
    this (uint id) {
	this._id = id;
	writeln ("Nouvelle données d'identifiant ", id);	
    }

    /++
     L'identifiant unique de la donnée
     Il doit être identique sur chacune des machines qui possèdent une référence.     
     +/
    ref uint id () {
	return this._id;
    }

    /++
     Génération d'un nouvelle identifiant de tableau unique
     Returns: le nouvelle identifiant
     +/
    protected static uint computeId () {
	__lastId__ ++;
	return __lastId__ - 1;
    }	

    
    
}
