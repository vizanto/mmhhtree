package;


/*
    valueOffsets  : Int32[numDatoms + 1] + padding;
    valueBytes    : Byte[ (valueOffsets[-1] - valueOffsets[0]),
    //                    at most: INLINE_VALUE_SIZE_LIMIT * numDatoms ] + padding;
*/
class InlineVariableBytesArray
{
    public final buffer : ReadOnlyMemory;
    public final offset : Int;
    public final length : Int;

    public inline function new(buffer, offset, length) {
        this.buffer = buffer;
        this.offset = offset;
        this.length = length;
    }

    public inline function getBytesStart(index) return buffer.getInt32(index);

    // public inline function get(index : Int) : InlineArray<Byte> {
    //     if(index < length) throw HHTreeError.outOfSegmentBounds;
    //     var valueStart = getBytesStart(index);
    //     var nextValue = getBytesStart(index + 1);
    //     // return buffer.readValue(this.offset + valueStart, nextValue - valueStart);
    //     return null;
    // }

    public inline function size() return getBytesStart(length);

    public inline function bytes() : ReadOnlyMemory
        // return buffer.slice(offset, offset + size());
        return null;
}
