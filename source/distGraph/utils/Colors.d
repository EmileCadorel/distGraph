module distGraph.utils.Colors;
import std.typecons;

alias Value = Tuple!(string, "value"); 

/++
 Enum de couleurs pour la génération en fichier .dot
+/
enum Color : Value {
    ROUGE = Value ("set19/1"),
    BLEUE = Value ("set19/2"),
    VERT = Value ("set19/3"),
    VIOLET = Value ("set19/4"),
    ORANGE = Value ("set19/5"),
    JAUNE = Value ("set19/6"),
    MARRON = Value ("set19/7"),
    PALE_VIOLET = Value ("set19/8"),
    GRIS = Value ("set19/9"),
}
