package;
import io.Bytes;

@:forward(get, getInt32, getInt64, length)
abstract ReadOnlyMemory (Bytes) to Bytes
{
    inline public function new (buffer : Bytes)
        // this = #if java buffer.asReadOnlyBuffer().order(java.nio.ByteOrder.LITTLE_ENDIAN) #else buffer #end;
        this = buffer;

    inline public function sub (index:Int, length:Int)
        return new ReadOnlyMemory(this.sub(index, length));
}
