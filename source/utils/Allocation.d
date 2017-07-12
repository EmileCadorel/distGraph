module utils.Allocation;
import core.memory;

T[] alloc(T) (ulong size) {
    return (cast (T*) GC.malloc(size * T.sizeof))[0 .. size];
}
