package;
import InlineArray.InlineArrayAPI;
import InlineArray.InlineArraySlice.*;
import InlineArray.ReadOnlyBufferSlice;
import InlineArray.ReadOnlyBufferSlice.pad64;

/*
    valueOffsets  : Int32[numDatoms + 1] + padding;
    valueBytes    : Byte[ (valueOffsets[-1] - valueOffsets[0]),
    //                    at most: INLINE_VALUE_SIZE_LIMIT * numDatoms ] + padding;
*/
/**
 * 64-byte padded variable length values (bytes)
 */
class InlineVariableBytesArray extends ReadOnlyBufferSlice implements InlineArrayAPI<ReadOnlyMemory>
{
    // the `inline` part of `inline new` is not inherited from super class
    public inline function new(buffer, offset, length) super(buffer, offset, length);

    public var bytes (get,never) : ReadOnlyMemory;
    inline function get_bytes () return new ReadOnlyMemory(buffer).sub(offset, sizeOf);

    public var sizeOf (get,never) : PositiveInt;
    @:pure public inline function get_sizeOf () return valueBytesOffset + pad64(getValueOffset(length));

    public var valueBytesOffset (get,never) : PositiveInt;
    @:pure public inline function get_valueBytesOffset () return offset + pad64(length + 1);

    /**
     * Get the relative position of the first byte of a value.
     * @param index which value to get an offset for
     * @return position relative to valueBytesOffset
     */
    @:pure public inline function getValueOffset (index:PositiveInt) : PositiveInt
        return PositiveInt.unsafeCast(buffer.getInt32(offset + index));

    @:pure inline private function get (index:PositiveInt)  {
        if (index > length) throw HHTreeError.outOfSegmentBounds;
        var valueStart = getValueOffset(index);
        var valueEnd   = getValueOffset(index + 1);
        return buffer.sub(valueBytesOffset + valueStart, valueEnd - valueStart);
    }

    @:pure inline public function nth    (index:Int) return this.get(index);

    @:pure public inline function sizeAt (index:PositiveInt) : PositiveInt
        return PositiveInt.unsafeCast(getValueOffset(index+1) - getValueOffset(index));

    inline public function slice (start:Int, end:Int) {
        var index = clampStart(start, this.length);
        var end = clampEnd(index, end, this.length);
        return null ;// new InlineVariableBytesArray(new ReadOnlyMemory(buffer), $i, end); // <== SHIT
    }
}
