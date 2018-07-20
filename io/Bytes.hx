package io;

#if (!display && java)
@:forward(asReadOnlyBuffer)
abstract Bytes(java.nio.ByteBuffer) from java.nio.ByteBuffer to java.nio.ByteBuffer
{
    public var length (get,never) : Int;
    inline public function get_length () return this.limit();

    inline public function get      (index : Int) return this.get(index);
    inline public function getInt32 (index : Int) return this.getInt(index);
    inline public function getInt64 (index : Int) return this.getLong(index);

    inline public function sub (index, length) : Bytes {
        var pos = this.position();
        var lim = this.limit();
        this.position(index);
        this.limit(index + length);
        trace(this);
        var buf = this.slice();
        trace(buf);
        this.position(pos);
        this.limit(lim);
        trace(this);
        return buf;
    }
}
#else
typedef Bytes = haxe.io.Bytes;
#end
