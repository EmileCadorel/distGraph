module dsl.syntax.Keys;
import dsl.syntax.Tokens;
import std.typecons;

enum Keys {
    IF = ("if"),
    RETURN = ("return"),
    FOR = ("for"),
    WHILE = ("while"),
    BREAK = ("break"),
    IN = ("in"),
    ELSE = ("else"),
    TRUE = ("true"),
    FALSE = ("false"),
    NULL = ("null"),
    CAST = ("cast"),
    FUNCTION = ("__kernel"),
    AUTO = ("auto"),
    IS = ("is"),
    NOT_IS = ("!is"),
    ANTI = ("\\"),
    LX = ("x"),
    STRUCT = ("struct"),
    LOCAL = ("__loc"),
    SKEL = ("__skel"),
    ALIAS = ("alias"),
    MIXIN = ("mixin")
}
